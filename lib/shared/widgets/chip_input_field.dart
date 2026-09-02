import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/utils/chip_text_logic.dart';

class ChipInputField<T extends Object> extends StatefulWidget {
  final String labelText;
  final List<T> allItems;

  /// Chips pre-committed on first display (e.g. an edit form showing
  /// the entity's saved relations). Seeded once at init; never
  /// triggers [onItemsChanged].
  final List<T>? initialItems;
  final String Function(T) itemToString;
  final double Function(String, T) similarityFn;
  final Future<T?> Function(String name) onCreateNew;
  final void Function(List<T> items) onItemsChanged;
  final Key? resetKey;

  /// When false (filter mode) unmatched segments are silently dropped
  /// instead of opening the create-new dialog, and the + button is
  /// hidden. Used by SEARCH where chips must reference real entities.
  final bool allowCreate;

  /// Optional collation comparator applied to dropdown when query is empty.
  final int Function(T a, T b)? sortFn;

  /// When non-null, only items whose ID is in this set appear in dropdown.
  final Set<int>? usedIds;

  /// Extracts the entity ID from an item (required when usedIds is set).
  final int Function(T)? getId;

  const ChipInputField({
    super.key,
    this.resetKey,
    required this.labelText,
    required this.allItems,
    this.initialItems,
    required this.itemToString,
    required this.similarityFn,
    required this.onCreateNew,
    required this.onItemsChanged,
    this.allowCreate = true,
    this.sortFn,
    this.usedIds,
    this.getId,
  });

  @override
  State<ChipInputField<T>> createState() => _ChipInputFieldState<T>();
}

class _ChipInputFieldState<T extends Object> extends State<ChipInputField<T>> {
  late _ChipTextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final List<T> _committedItems = [];
  String _activeText = '';
  bool _showDropdown = false;
  bool _suppressAutocomplete = false;
  String _previousText = '';
  bool _isRebuilding = false;
  String _committedPrefix = '';
  int _highlightIndex = -1;
  List<T>? _previewItems;
  final ScrollController _dropdownScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = _ChipTextEditingController(
      committedTextStyle: const TextStyle(
        color: AppColors.textHint,
        fontSize: 14,
      ),
      activeTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
    );
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    // Seed saved chips (edit forms). Bypasses _addCommittedItem so
    // no onItemsChanged callback fires during construction.
    final seed = widget.initialItems;
    if (seed != null && seed.isNotEmpty) {
      _committedItems.addAll(seed);
      _rebuildControllerText();
    }
  }

  @override
  void didUpdateWidget(ChipInputField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) {
      _committedItems.clear();
      _activeText = '';
      _suppressAutocomplete = false;
      _committedPrefix = '';
      _highlightIndex = -1;
      _previewItems = null;
      _controller
        ..committedLength = 0
        ..text = '';
      _previousText = '';
      _focusNode.unfocus();
      setState(() => _showDropdown = false);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() => _showDropdown = true);
    } else {
      _highlightIndex = -1;
      _previewItems = null;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showDropdown = false);
        }
      });
    }
  }

  void _onTextChanged() {
    if (_isRebuilding) return;

    final newText = _controller.text;

    // Destructive edit removed part/all of the committed region:
    // drop chips whose grey text no longer survives.
    if (!_reconcileChipsWithText(newText)) return;

    _highlightIndex = -1;
    _previewItems = null;

    if (newText.length - _previousText.length > 1) {
      final start = _previousText.length.clamp(0, newText.length);
      final pastedText = newText.substring(start);
      if (pastedText.contains(',')) {
        _suppressAutocomplete = true;
      }
    }

    final committedLen = _controller.committedLength.clamp(0, newText.length);
    _activeText = newText.substring(committedLen);

    if (_activeText.endsWith(',') && !_suppressAutocomplete) {
      final segment = _activeText.substring(0, _activeText.length - 1).trim();
      _activeText = '';
      _commitSegment(segment);
      setState(() {});
      return;
    }

    _previousText = newText;
    setState(() {});
  }

  /// Reconciles chips with the surviving committed prefix after a
  /// destructive edit. Returns false when it rebuilt the controller
  /// (the caller must stop processing this change).
  bool _reconcileChipsWithText(String newText) {
    final prevCommitted = _committedPrefix.length;
    if (_committedItems.isEmpty || prevCommitted == 0) return true;

    final greyIntact = newText.length >= prevCommitted &&
        newText.substring(0, prevCommitted) == _committedPrefix;
    if (greyIntact) return true;

    final keptSource = newText.length <= prevCommitted
        ? newText
        : newText.substring(0, prevCommitted);

    final keptNorms = ChipTextLogic.splitSegments(keptSource)
        .map(ChipTextLogic.normalizeForMatch)
        .toSet();

    final surviving = _committedItems
        .where((item) => keptNorms.contains(
            ChipTextLogic.normalizeForMatch(widget.itemToString(item))))
        .toList();

    if (surviving.length == _committedItems.length) return true;

    _committedItems
      ..clear()
      ..addAll(surviving);
    widget.onItemsChanged(List.from(_committedItems));

    _activeText = '';
    _rebuildControllerText();
    setState(() {});
    return false;
  }

  void _commitSegment(String segment) {
    if (segment.isEmpty) {
      _rebuildControllerText();
      return;
    }

    final match = _findExactCaseInsensitive(segment);

    if (match != null) {
      debugPrint('[ChipInputField] type2 HIT: "$segment" '
          '-> "${widget.itemToString(match)}"');
      _addCommittedItem(match);
      _rebuildControllerText();
    } else {
      debugPrint('[ChipInputField] type2 MISS: "$segment" '
          '(norm="${ChipTextLogic.normalizeForMatch(segment)}", '
          'nearest=${_nearestCandidateDebug(segment)})');
      _rebuildControllerText();
      if (widget.allowCreate) _showCreateModal(segment);
    }
  }

  T? _findExactCaseInsensitive(String segment) {
    final names = widget.allItems.map(widget.itemToString).toList();
    final canonicalName = ChipTextLogic.matchType2(segment, names);
    if (canonicalName == null) return null;
    for (final item in widget.allItems) {
      if (widget.itemToString(item) == canonicalName) return item;
    }
    return null;
  }

  String _nearestCandidateDebug(String segment) {
    String bestName = '';
    var bestScore = -1.0;
    for (final item in widget.allItems) {
      final score = widget.similarityFn(segment, item);
      if (score > bestScore) {
        bestScore = score;
        bestName = widget.itemToString(item);
      }
    }
    if (bestName.isEmpty) return '(no candidates loaded)';
    return '"$bestName" '
        '(norm="${ChipTextLogic.normalizeForMatch(bestName)}", '
        'score=${bestScore.toStringAsFixed(2)})';
  }

  void _addCommittedItem(T item) {
    final name = widget.itemToString(item);
    if (_committedItems.any((e) => widget.itemToString(e) == name)) {
      return;
    }
    _committedItems.add(item);
    widget.onItemsChanged(List.from(_committedItems));
  }

  void _removeCommittedItem(T item) {
    _committedItems.remove(item);
    _rebuildControllerText();
    widget.onItemsChanged(List.from(_committedItems));
    setState(() {});
  }

  void _reorderCommittedItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _committedItems.removeAt(oldIndex);
    _committedItems.insert(newIndex, item);
    _rebuildControllerText();
    widget.onItemsChanged(List.from(_committedItems));
    setState(() {});
  }

  void _rebuildControllerText() {
    _isRebuilding = true;

    final prefix = _committedItems.map(widget.itemToString).join(', ');
    final separator = prefix.isNotEmpty ? ', ' : '';
    final newText = '$prefix$separator$_activeText';
    final newCommittedLength = '$prefix$separator'.length;

    _committedPrefix = '$prefix$separator';

    _controller
      ..committedLength = newCommittedLength
      ..text = newText;

    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );

    _previousText = newText;
    _isRebuilding = false;
  }

  Future<void> _showCreateModal(String name) async {
    final result = await widget.onCreateNew(name);
    if (result != null) {
      _addCommittedItem(result);
    }
    _rebuildControllerText();
    if (mounted) setState(() {});
  }

  void _handleEnter() {
    _suppressAutocomplete = false;

    // Part A — a highlighted (arrow-selected) recommendation commits the WHOLE
    // suggestion, comma and all, exactly like a mouse tap. We must never
    // re-parse the text here: an artist name like "Earth, Wind and Fire"
    // contains a comma that is a part of the name, not a value separator.
    if (_previewItems != null &&
        _previewItems!.isNotEmpty &&
        _highlightIndex >= 0 &&
        _highlightIndex < _previewItems!.length) {
      _onAutocompleteSelected(_previewItems![_highlightIndex]);
      return;
    }

    final activeText = _activeText.trim();
    if (activeText.isEmpty) return;

    // Part B — if the ENTIRE active text exactly matches one existing entity,
    // commit it as that single entity (comma and all) rather than splitting.
    // Only falls through to comma-splitting when the whole text is NOT a single
    // known entity (i.e. a genuine multi-value paste like "Denzel Curry, Jazz").
    if (_findExactCaseInsensitive(activeText) != null) {
      final single = _findExactCaseInsensitive(activeText)!;
      debugPrint('[ChipInputField] full-text single match: "$activeText" '
          '-> "${widget.itemToString(single)}"');
      _addCommittedItem(single);
      _activeText = '';
      _rebuildControllerText();
      setState(() {});
      return;
    }

    final segments = ChipTextLogic.splitSegments(activeText);
    final unmatched = <String>[];

    for (final segment in segments) {
      final match = _findExactCaseInsensitive(segment);
      if (match != null) {
        debugPrint('[ChipInputField] type2 HIT: "$segment" '
            '-> "${widget.itemToString(match)}"');
        _addCommittedItem(match);
      } else {
        debugPrint('[ChipInputField] type2 MISS: "$segment" '
            '(norm="${ChipTextLogic.normalizeForMatch(segment)}", '
            'nearest=${_nearestCandidateDebug(segment)})');
        unmatched.add(segment);
      }
    }

    _activeText = '';
    _rebuildControllerText();
    setState(() {});

    if (unmatched.isNotEmpty && widget.allowCreate) {
      _showUnmatchedModals(unmatched);
    }
  }

  Future<void> _showUnmatchedModals(List<String> unmatched) async {
    for (final name in unmatched) {
      await _showCreateModal(name);
    }
  }

  void _onAutocompleteSelected(T item) {
    debugPrint('[ChipInputField] recommendation tapped -> committing '
        '"${widget.itemToString(item)}"');
    _highlightIndex = -1;
    _previewItems = null;
    _addCommittedItem(item);
    _activeText = '';
    _rebuildControllerText();
    setState(() {});
  }

  /// Arrow-key navigation: moves the highlighted recommendation and
  /// replaces the active text as a PREVIEW only. The user still presses
  /// Enter/comma/+ to commit; arrows never auto-commit.
  void _moveHighlight(int delta) {
    // Cache the recommendation list at the moment the user first presses an
    // arrow so previewing does not shrink the list to the previewed name
    // itself. Rebuilt from a fresh query on the next user edit.
    _previewItems ??= _getFilteredItems(_activeText);
    final items = _previewItems!;
    if (items.isEmpty) {
      _highlightIndex = -1;
      _previewItems = null;
      return;
    }
    final n = items.length;
    if (_highlightIndex < 0 || _highlightIndex >= n) {
      _highlightIndex = delta > 0 ? 0 : n - 1;
    } else {
      _highlightIndex = (_highlightIndex + delta) % n;
      if (_highlightIndex < 0) _highlightIndex += n;
    }
    _previewAt(_highlightIndex, items);
  }

  void _previewAt(int index, List<T> items) {
    final preview = widget.itemToString(items[index]);
    _activeText = preview;
    _rebuildControllerText();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollHighlightIntoView();
    });
  }

  void _scrollHighlightIntoView() {
    if (_highlightIndex < 0) return;
    if (!_dropdownScrollController.hasClients) return;
    final index = _highlightIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _highlightIndex != index) return;
      if (!_dropdownScrollController.hasClients) return;
      _dropdownScrollController.animateTo(
        (index * 40.0).clamp(
          0.0,
          _dropdownScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  List<T> _getFilteredItems(String query) {
    final committedNames = _committedItems.map(widget.itemToString).toSet();

    var candidates = widget.allItems
        .where((item) => !committedNames.contains(widget.itemToString(item)))
        .toList();

    if (widget.usedIds != null && widget.getId != null) {
      candidates =
          candidates.where((item) => widget.usedIds!.contains(widget.getId!(item))).toList();
    }

    if (query.isEmpty) {
      if (widget.sortFn != null) {
        candidates.sort(widget.sortFn);
      }
      return candidates;
    }

    return candidates
        .where((item) =>
            widget.similarityFn(query, item) > 0.3 ||
            widget
                .itemToString(item)
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList()
        ..sort((a, b) => widget
            .similarityFn(query, b)
            .compareTo(widget.similarityFn(query, a)));
  }

  /// Single source of truth for the dropdown — used by BOTH the arrow-key
  /// navigation (`_moveHighlight`) and the visible list. While a preview
  /// session is active the cached [_previewItems] is shown so highlighting
  /// can never drift out of sync with what the user sees; otherwise the list
  /// is recomputed live from the active text.
  List<T> get _displayItems {
    if (_previewItems != null && _previewItems!.isNotEmpty) {
      return _previewItems!;
    }
    return _getFilteredItems(_activeText);
  }

  @override
  void dispose() {
    _dropdownScrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _displayItems;
    final chipLabelWidth = _maxChipLabelWidth();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) {
              return KeyEventResult.ignored;
            }
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.arrowDown ||
                key == LogicalKeyboardKey.arrowUp) {
              _moveHighlight(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
              return KeyEventResult.handled;
            }
            if (event is! KeyRepeatEvent &&
                (key == LogicalKeyboardKey.enter ||
                    key == LogicalKeyboardKey.numpadEnter)) {
              _handleEnter();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
            labelText: widget.labelText,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppColors.electricBlue, size: 20),
                  tooltip: 'Confirm',
                  onPressed: _handleEnter,
                ),
                if (widget.allowCreate)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.teal, size: 20),
                    tooltip: '+ Create New',
                    onPressed: () {
                      if (_activeText.trim().isNotEmpty) {
                        _showCreateModal(_activeText.trim());
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
        ),
        if (_showDropdown && filteredItems.isNotEmpty && !_suppressAutocomplete)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              elevation: 8,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 200, minWidth: 200),
                child: ListView.builder(
                  controller: _dropdownScrollController,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final option = filteredItems[index];
                    final highlighted = index == _highlightIndex;
                    return InkWell(
                      onTap: () => _onAutocompleteSelected(option),
                      onTapDown: (_) {
                        if (!_focusNode.hasFocus) _focusNode.requestFocus();
                      },
                      child: Container(
                        color: highlighted
                            ? AppColors.grid.withOpacity(0.55)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          widget.itemToString(option),
                          style: TextStyle(
                            color: highlighted
                                ? AppColors.electricBlue
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: highlighted
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        if (_committedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _committedItems.length,
              onReorder: (oldIndex, newIndex) =>
                  _reorderCommittedItems(oldIndex, newIndex),
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final item = _committedItems[index];
                return ReorderableDragStartListener(
                  key: ValueKey('reorder_${widget.itemToString(item)}_$index'),
                  index: index,
                  child: _buildChip(item, index, chipLabelWidth),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Width of the longest committed label. Every chip is sized to this
  /// so all chips render identical; recomputed on every build, i.e.
  /// whenever a chip is added or removed.
  double _maxChipLabelWidth() {
    var maxW = 0.0;
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );
    for (final item in _committedItems) {
      tp.text = TextSpan(
        text: widget.itemToString(item),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
      );
      tp.layout();
      if (tp.width > maxW) maxW = tp.width;
    }
    return maxW;
  }

  Widget _buildChip(T item, int index, double labelWidth) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        key: ValueKey('chip_${widget.itemToString(item)}_$index'),
        avatar: const Icon(
          Icons.drag_handle,
          size: 22,
          color: Color(0xFF388E3C),
        ),
        label: SizedBox(
          width: labelWidth,
          child: Text(
            widget.itemToString(item),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
        deleteIcon: const Icon(
          Icons.close,
          size: 19,
          color: AppColors.error,
        ),
        onDeleted: () => _removeCommittedItem(item),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
    );
  }
}

class _ChipTextEditingController extends TextEditingController {
  final TextStyle committedTextStyle;
  final TextStyle activeTextStyle;
  int committedLength = 0;

  _ChipTextEditingController({
    required this.committedTextStyle,
    required this.activeTextStyle,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty || committedLength == 0) {
      return TextSpan(text: text, style: style ?? activeTextStyle);
    }

    final clamped = committedLength.clamp(0, text.length);

    return TextSpan(
      style: style,
      children: [
        TextSpan(
          text: text.substring(0, clamped),
          style: committedTextStyle,
        ),
        TextSpan(
          text: text.substring(clamped),
          style: activeTextStyle,
        ),
      ],
    );
  }
}
