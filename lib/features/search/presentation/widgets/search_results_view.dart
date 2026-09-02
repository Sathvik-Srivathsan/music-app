import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/features/search/domain/search_query.dart';
import 'package:music_collection/features/search/presentation/providers/search_provider.dart';
import 'package:music_collection/features/search/presentation/widgets/edit_record_modal.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:provider/provider.dart';

class _Col {
  final String field;
  final String label;
  final bool rightAlign;
  const _Col(this.field, this.label, {this.rightAlign = false});
}

class _Item {
  final String? groupKey;
  final RecordDetails? record;
  final int zebra;
  const _Item.group(this.groupKey)
      : record = null,
        zebra = 0;
  const _Item.row(this.record, this.zebra) : groupKey = null;
  bool get isGroup => groupKey != null;
}

class SearchResultsView extends StatelessWidget {
  final VoidCallback? onBackToSearch;
  final String originTab;
  const SearchResultsView({super.key, this.onBackToSearch, this.originTab = 'search'});

  static const _masterCols = [
    _Col('name', 'Record Name'),
    _Col('artists', 'Artists'),
    _Col('genres', 'Genres'),
    _Col('descriptors', 'Descriptors'),
    _Col('releaseDate', 'Release Date', rightAlign: true),
    _Col('type', 'Type'),
    _Col('dateAdded', 'Date Added', rightAlign: true),
    _Col('streaming', 'Streaming'),
    _Col('comments', 'Comments'),
  ];

  static const double _rowHeight = 44;
  static const double _bandHeight = 30;

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchResultsProvider>(
      builder: (context, p, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerRow(context, p),
                  const SizedBox(height: 12),
                  Text(
                    '${p.totalRows} record${p.totalRows == 1 ? '' : 's'}'
                    ' found (Active ${p.activeResults.length} / '
                    'Finished ${p.finishedResults.length})',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: p.totalRows == 0
                        ? _emptyState(p)
                        : _tableArea(context, p),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_Col> _visibleCols(SearchResultsProvider p) {
    if (p.hideShowColumns) return _masterCols;
    return [
      for (final c in _masterCols)
        if (p.isColumnShown(c.field)) c,
    ];
  }

  Widget _headerRow(BuildContext context, SearchResultsProvider p) {
    return LayoutBuilder(builder: (context, cons) {
      final actions = <Widget>[
        if (onBackToSearch != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lavenderPurple,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 40),
            ),
            onPressed: onBackToSearch,
            icon: const Icon(Icons.arrow_back,
                size: 16, color: AppColors.background),
            label: const Text('Back to Search',
                style: TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.w600)),
          ),
        SegmentedButton<ResultBucket>(
          segments: [
            ButtonSegment(
              value: ResultBucket.active,
              label: Text('Active (${p.activeResults.length})'),
            ),
            ButtonSegment(
              value: ResultBucket.finished,
              label: Text('Finished (${p.finishedResults.length})'),
            ),
          ],
          selected: {p.currentBucket},
          onSelectionChanged: (s) => p.setBucket(s.first),
          style: SegmentedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            selectedForegroundColor: AppColors.background,
            selectedBackgroundColor: AppColors.electricBlue,
          ),
        ),
        if (!p.hideShowColumns)
          _ColumnsPickerButton(provider: p, masterCols: _masterCols),
        DropdownButton<String>(
          value: p.groupByField ?? '',
          dropdownColor: AppColors.card,
          hint: const Text('Group by',
              style: TextStyle(
                  color: AppColors.textHint, fontSize: 13)),
          items: const [
            DropdownMenuItem(value: '', child: Text('No grouping')),
            DropdownMenuItem(
                value: 'name', child: Text('Record Name')),
            DropdownMenuItem(
                value: 'artists', child: Text('Artists')),
            DropdownMenuItem(
                value: 'genres', child: Text('Genres')),
            DropdownMenuItem(
                value: 'descriptors', child: Text('Descriptors')),
            DropdownMenuItem(
                value: 'releaseDate', child: Text('Release Date')),
            DropdownMenuItem(value: 'type', child: Text('Type')),
            DropdownMenuItem(
                value: 'dateAdded', child: Text('Date Added')),
            DropdownMenuItem(
                value: 'streaming', child: Text('Streaming')),
            DropdownMenuItem(
                value: 'comments', child: Text('Comments')),
          ],
          onChanged: (v) =>
              p.setGroupBy(v == null || v.isEmpty ? null : v),
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 13),
        ),
        if (p.groupByField != null &&
            p.groupedRows.length > 1)
          _GroupReorderButton(provider: p),
        if (p.sortColumns.isNotEmpty)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amberGold,
              foregroundColor: AppColors.background,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => p.clearSorts(),
            child: Text(
              'Clear sorts (${p.sortColumns.length})',
              style: const TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ];

      if (cons.maxWidth < 1450) {
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        );
      }
      final left = actions.take(3).toList();
      final right = actions.skip(3).toList();
      return Row(
        children: [
          for (var i = 0; i < left.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            left[i],
          ],
          const Spacer(),
          for (var i = 0; i < right.length; i++) ...[
            right[i],
            if (i < right.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    });
  }

  Widget _emptyState(SearchResultsProvider p) {
    final hasQuery = p.query.isFilled;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off : Icons.inbox_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery
                ? 'Zero records matched these parameters.'
                : 'No records matched - your library has no rows yet.',
            style:
                const TextStyle(color: AppColors.textSecondary),
          ),
          if (hasQuery) ...[
            const SizedBox(height: 8),
            Text(
              'Try removing a naming filter or loosening the dates.',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  List<_Item> _buildItems(SearchResultsProvider p) {
    final rows = p.sortedRows;
    if (p.groupByField == null) {
      return [
        for (var i = 0; i < rows.length; i++)
          _Item.row(rows[i], i),
      ];
    }

    final field = p.groupByField!;
    final groups = <String, List<RecordDetails>>{};
    for (final r in rows) {
      for (final key
          in SearchQueryEngine.groupKeysFor(r, field)) {
        (groups[key] ??= []).add(r);
      }
    }

    final encounter = <String>[for (final k in groups.keys) k];
    final ov = p.groupOrderOverride;
    final ordered = ov.isEmpty
        ? encounter
        : (encounter.toList()
          ..sort((a, b) {
            final ra = ov[a];
            final rb = ov[b];
            if (ra != null && rb != null) return ra.compareTo(rb);
            if (ra != null) return -1;
            if (rb != null) return 1;
            return 0;
          }));

    final items = <_Item>[];
    var zebra = 0;
    for (final key in ordered) {
      items.add(_Item.group(key));
      for (final r in groups[key]!) {
        items.add(_Item.row(r, zebra));
        zebra++;
      }
    }
    return items;
  }

  Widget _tableArea(BuildContext context, SearchResultsProvider p) {
    return _ResultsTable(
      items: _buildItems(p),
      cols: _visibleCols(p),
      originTab: originTab,
    );
  }
}

// ── Displaying Columns picker ────────────────────────────────────

class _ColumnsPickerButton extends StatefulWidget {
  final SearchResultsProvider provider;
  final List<_Col> masterCols;
  const _ColumnsPickerButton(
      {required this.provider, required this.masterCols});

  @override
  State<_ColumnsPickerButton> createState() =>
      _ColumnsPickerButtonState();
}

class _ColumnsPickerButtonState
    extends State<_ColumnsPickerButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  static const double _panelW = 260;

  void _toggle() => _entry != null ? _close() : _open();

  void _open() {
    _entry = OverlayEntry(builder: (ctx) {
      final screen = MediaQuery.of(ctx).size;
      final box =
          context.findRenderObject() as RenderBox;
      final btnTopLeft =
            box.localToGlobal(Offset.zero);
      final btnH = box.size.height;
      final panelH =
          (widget.masterCols.length * 48.0 + 16).clamp(0.0, screen.height * 0.6);

      final openUp =
          btnTopLeft.dy + btnH + panelH > screen.height - 8;
      var dx = btnTopLeft.dx;
      if (dx + _panelW > screen.width - 8) {
        dx = screen.width - _panelW - 8;
      }
      if (dx < 8) dx = 8;

      // Downward: panel top-left at button bottom-left.
      // Upward:   panel bottom-left at button top-left.
      final targetAnchor =
          openUp ? Alignment.topLeft : Alignment.bottomLeft;
      final followerAnchor =
          openUp ? Alignment.bottomLeft : Alignment.topLeft;
      final yOffset = openUp ? -6.0 : 6.0;

      return Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _close(),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: Offset(dx - btnTopLeft.dx, yOffset),
            child: Material(
              elevation: 8,
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildPanel(panelH),
            ),
          ),
        ],
      );
    });
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  Widget _buildPanel(double maxH) {
    final p = widget.provider;
    return Container(
      width: _panelW,
      constraints: BoxConstraints(maxHeight: maxH),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Displaying Columns',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.masterCols.length,
              itemBuilder: (ctx, i) {
                final col = widget.masterCols[i];
                final frozen = {'name', 'artists', 'genres'}
                    .contains(col.field);
                final shown = p.isColumnShown(col.field);
                return CheckboxListTile(
                  value: shown,
                  onChanged: frozen
                      ? null
                      : (v) {
                          p.setColumnVisible(col.field, v ?? false);
                          _entry?.markNeedsBuild();
                        },
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(col.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13)),
                      ),
                      if (frozen)
                        const Icon(Icons.lock,
                            size: 12,
                            color: AppColors.textHint),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderLight),
          minimumSize: const Size(0, 40),
        ),
        onPressed: _toggle,
        icon: const Icon(Icons.view_column_outlined, size: 16),
        label: const Text('Show Columns'),
      ),
    );
  }
}

// ── Reorder Groups button + bounded overlay ──────────────────────

class _GroupReorderButton extends StatefulWidget {
  final SearchResultsProvider provider;
  const _GroupReorderButton({required this.provider});

  @override
  State<_GroupReorderButton> createState() =>
      _GroupReorderButtonState();
}

class _GroupReorderButtonState extends State<_GroupReorderButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  List<String>? _localKeys;

  static const double _panelW = 360;

  void _toggle() => _entry != null ? _close() : _open();

  void _open() {
    _localKeys = [
      for (final e in widget.provider.groupedRows) e.key
    ];
    _entry = OverlayEntry(builder: (ctx) {
      final screen = MediaQuery.of(ctx).size;
      final box = context.findRenderObject() as RenderBox;
      final btnTopLeft = box.localToGlobal(Offset.zero);
      final btnH = box.size.height;
      final maxPanelH = screen.height * 0.6;

      final openUp =
          btnTopLeft.dy + btnH + maxPanelH > screen.height - 8;
      var dx = btnTopLeft.dx;
      if (dx + _panelW > screen.width - 8) {
        dx = screen.width - _panelW - 8;
      }
      if (dx < 8) dx = 8;

      // Downward: panel top-left at button bottom-left.
      // Upward:   panel bottom-left at button top-left.
      final targetAnchor =
          openUp ? Alignment.topLeft : Alignment.bottomLeft;
      final followerAnchor =
          openUp ? Alignment.bottomLeft : Alignment.topLeft;
      final yOffset = openUp ? -6.0 : 6.0;

      return Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _close(),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: Offset(dx - btnTopLeft.dx, yOffset),
            child: Material(
              elevation: 8,
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildPanel(maxPanelH),
            ),
          ),
        ],
      );
    });
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    _localKeys = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  Widget _buildPanel(double maxH) {
    final keys = _localKeys!;
    final p = widget.provider;

    void moveChip(String dragged, String target) {
      if (dragged == target) return;
      final list = keys.toList()..remove(dragged);
      final tIdx = list.indexOf(target);
      list.insert(tIdx, dragged);
      _localKeys = list;
      p.reorderGroups(list);
      _entry?.markNeedsBuild();
    }

    return Container(
      width: _panelW,
      constraints: BoxConstraints(maxHeight: maxH),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Reorder Groups',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (p.groupOrderOverride.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _localKeys = [
                      for (final e in p.groupedRows) e.key
                    ];
                    p.reorderGroups([]);
                    _entry?.markNeedsBuild();
                  },
                  child: const Text('Reset',
                      style: TextStyle(fontSize: 12)),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close,
                    size: 16, color: AppColors.textSecondary),
                onPressed: _close,
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: keys.length,
              itemBuilder: (ctx, i) {
                final key = keys[i];
                return DragTarget<String>(
                  onWillAccept: (d) =>
                      d != null && d != key,
                  onAccept: (d) => moveChip(d, key),
                  builder: (ctx, cand, rej) {
                    final hovering =
                        cand.isNotEmpty && cand.first != key;
                    return Draggable<String>(
                      data: key,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Chip(
                          backgroundColor: AppColors.electricBlue
                              .withOpacity(0.6),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxWidth: 220),
                            child: Text(key,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color:
                                        AppColors.textPrimary,
                                    fontSize: 11)),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _chipTile(key, false)),
                      child: _chipTile(key, hovering),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipTile(String key, bool highlight) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.electricBlue.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Expanded(
              child: Text(key,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side:
              const BorderSide(color: AppColors.borderLight),
          minimumSize: const Size(0, 40),
        ),
        onPressed: _toggle,
        icon: const Icon(Icons.low_priority, size: 16),
        label: const Text('Reorder Groups'),
      ),
    );
  }
}

// ── Results table with equal-width columns + scroll pills ────────

class _ResultsTable extends StatefulWidget {
  final List<_Item> items;
  final List<_Col> cols;
  final String originTab;
  const _ResultsTable(
      {required this.items, required this.cols, required this.originTab});

  @override
  State<_ResultsTable> createState() => _ResultsTableState();
}

class _ResultsTableState extends State<_ResultsTable> {
  static const double _headerH = 40;
  ScrollController? _rightCtrl;
  ScrollController? _hCtrl;

  double _lastTableWidth = 0;
  double _lastColW = 0;
  List<String> _prevLeftCols = const [];
  List<String> _prevRightCols = const [];

  @override
  void dispose() {
    _hCtrl?.removeListener(_onHScroll);
    _rightCtrl?.dispose();
    _hCtrl?.dispose();
    super.dispose();
  }

  void _ensureControllers() {
    if (_rightCtrl != null) return;
    _rightCtrl = ScrollController();
    _hCtrl = ScrollController()..addListener(_onHScroll);
  }

  void _onHScroll() {
    if (!mounted) return;
    if (_lastTableWidth == 0) return;
    final cols = widget.cols;
    if (cols.length <= 5) return;
    final hOffset =
        _hCtrl?.hasClients == true ? _hCtrl!.offset : 0.0;
    final left = <String>[];
    final right = <String>[];
    for (var i = 0; i < cols.length; i++) {
      final colStart = i * _lastColW;
      if (colStart < hOffset - 0.5) left.add(cols[i].label);
      if (colStart >= hOffset + _lastTableWidth - 0.5) {
        right.add(cols[i].label);
      }
    }
    if (left.length == _prevLeftCols.length &&
        right.length == _prevRightCols.length &&
        _listEquals(left, _prevLeftCols) &&
        _listEquals(right, _prevRightCols)) {
      return;
    }
    _prevLeftCols = left;
    _prevRightCols = right;
    setState(() {});
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant _ResultsTable old) {
    super.didUpdateWidget(old);
    if (!identical(widget.items, old.items) ||
        !identical(widget.cols, old.cols)) {
      _prevLeftCols = const [];
      _prevRightCols = const [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();
    final p = context.read<SearchResultsProvider>();
    final items = widget.items;
    final cols = widget.cols;

    return LayoutBuilder(builder: (context, cons) {
      final tableWidth = cons.maxWidth;
      final n = cols.length;
      final colW = tableWidth / (n < 5 ? n : 5).toDouble();
      final scrollable = n > 5;
      _lastTableWidth = tableWidth;
      _lastColW = colW;

      final leftColNames = <String>[];
      final rightColNames = <String>[];
      if (scrollable) {
        final hOffset =
            _hCtrl?.hasClients == true ? _hCtrl!.offset : 0.0;
        for (var i = 0; i < cols.length; i++) {
          final colStart = i * colW;
          if (colStart < hOffset - 0.5) {
            leftColNames.add(cols[i].label);
          }
          if (colStart >= hOffset + tableWidth - 0.5) {
            rightColNames.add(cols[i].label);
          }
        }
      }

      final dataPane = scrollable
          ? _scrollableDataPane(cols, items, colW, p)
          : _fixedDataPane(cols, items, tableWidth, p);

      return Column(
        children: [
          if (scrollable &&
              (leftColNames.isNotEmpty || rightColNames.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (leftColNames.isNotEmpty)
                    _ScrollPill(
                      label: '← ${leftColNames.join(', ')}',
                      onTap: () {
                        _hCtrl?.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  const Spacer(),
                  if (rightColNames.isNotEmpty)
                    _ScrollPill(
                      label: '${rightColNames.join(', ')} →',
                      onTap: () {
                        _hCtrl?.animateTo(
                          _hCtrl!.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: dataPane,
            ),
          ),
        ],
      );
    });
  }

  Widget _scrollableDataPane(
    List<_Col> cols,
    List<_Item> items,
    double colW,
    SearchResultsProvider p,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: Scrollbar(
            controller: _hCtrl,
            thumbVisibility: true,
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: _hCtrl,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: colW * cols.length,
                  child: Column(
                    children: [
                      SizedBox(
                        height: _headerH,
                        child: Row(
                          children: [
                            for (final col in cols)
                              _headerCell(p, col, colW),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _rightCtrl,
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final it = items[i];
                            return it.isGroup
                                ? _bandCellRight(it.groupKey!)
                                : _bodyRow(it.record!, it.zebra,
                                    cols, colW);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: _headerH,
          bottom: 0,
          width: 14,
          child: _VerticalScrollTrack(ctrl: _rightCtrl!),
        ),
      ],
    );
  }

  Widget _fixedDataPane(
    List<_Col> cols,
    List<_Item> items,
    double dataVisible,
    SearchResultsProvider p,
  ) {
    final colW = cols.isEmpty ? dataVisible : dataVisible / cols.length;
    return Column(
      children: [
        SizedBox(
          height: _headerH,
          child: Row(
            children: [
              for (final col in cols)
                _headerCell(p, col, colW),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _rightCtrl,
            thumbVisibility: true,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: ListView.builder(
                controller: _rightCtrl,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final it = items[i];
                  return it.isGroup
                      ? _bandCellRight(it.groupKey!)
                      : _bodyRow(
                          it.record!, it.zebra, cols, colW);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Cells ---

  Widget _headerCell(SearchResultsProvider p, _Col col, double w) {
    return Expanded(
      child: InkWell(
        onTap: () => p.cycleSort(col.field),
        hoverColor: AppColors.grid.withOpacity(0.4),
        child: Container(
          height: _headerH,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            border: Border(
                right: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: col.rightAlign
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(col.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              _sortBadge(col.field),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bandCellRight(String key) {
    return Container(
      height: SearchResultsView._bandHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      alignment: Alignment.centerLeft,
      child: Text(key,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.electricBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    );
  }

  String _cellText(RecordDetails r, _Col col) {
    switch (col.field) {
      case 'name':
        return r.record.recordName;
      case 'artists':
        return r.artistsCsv;
      case 'genres':
        return r.genresCsv;
      case 'descriptors':
        return r.descriptorsCsv;
      case 'releaseDate':
        return r.record.releaseDate ?? '';
      case 'type':
        return r.record.recordType ?? '';
      case 'dateAdded':
        return r.record.dateAdded ?? '';
      case 'streaming':
        return r.streamingDisplayNames.join(', ');
      case 'comments':
        return r.record.comments ?? '';
      default:
        return '';
    }
  }

  Widget _sortBadge(String field) {
    final p = context.read<SearchResultsProvider>();
    final idx = p.sortPriority(field);
    if (idx == 0) return const SizedBox.shrink();
    final sc = p.sortColumns[idx - 1];
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.amberGold.withOpacity(0.25),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$idx',
              style: const TextStyle(
                  color: AppColors.amberGold, fontSize: 9)),
          Icon(
              sc.ascending
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 12,
              color: AppColors.amberGold),
        ],
      ),
    );
  }

  Color _rowBg(int i) =>
      i.isEven ? AppColors.background : AppColors.card.withOpacity(0.5);

  Widget _bodyRow(
      RecordDetails r, int i, List<_Col> cols, double colW) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showEditRecordModal(context, r, originTab: widget.originTab),
        child: SizedBox(
          height: SearchResultsView._rowHeight,
          child: Row(children: [
            for (final col in cols) _dataCell(r, col, colW, i),
          ]),
        ),
      ),
    );
  }

  Widget _dataCell(RecordDetails r, _Col col, double w, int zebra) {
    final child = col.field == 'name'
        ? Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: r.record.status
                      ? AppColors.amberGold
                      : AppColors.active,
                ),
              ),
              Expanded(
                child: Text(r.record.recordName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 12)),
              ),
            ],
          )
        : Tooltip(
            message: _cellText(r, col),
            showDuration: const Duration(seconds: 3),
            child: Text(_cellText(r, col),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: col.rightAlign
                    ? TextAlign.right
                    : TextAlign.left,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          );
    return Expanded(
      child: Container(
        height: SearchResultsView._rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _rowBg(zebra),
          border: const Border(
              right: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border)),
        ),
        alignment: col.field == 'name'
            ? Alignment.centerLeft
            : (col.rightAlign
                ? Alignment.centerRight
                : Alignment.centerLeft),
        child: child,
      ),
    );
  }
}

// ── Scroll indicator pill ────────────────────────────────────────

class _ScrollPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _ScrollPill({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.92),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.electricBlue, width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.electricBlue,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ── Fixed vertical scroll track (Stack overlay) ──────────────────

class _VerticalScrollTrack extends StatefulWidget {
  final ScrollController ctrl;
  const _VerticalScrollTrack({required this.ctrl});

  @override
  State<_VerticalScrollTrack> createState() => _VerticalScrollTrackState();
}

class _VerticalScrollTrackState extends State<_VerticalScrollTrack> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _VerticalScrollTrack old) {
    super.didUpdateWidget(old);
    if (old.ctrl != widget.ctrl) {
      old.ctrl.removeListener(_onScroll);
      widget.ctrl.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackH = constraints.maxHeight;
        if (!widget.ctrl.hasClients || trackH <= 0) {
          return const SizedBox.shrink();
        }
        final pos = widget.ctrl.position;
        final maxScroll = pos.maxScrollExtent;
        final offset = widget.ctrl.offset;

        if (maxScroll <= 0) {
          return const SizedBox.shrink();
        }

        final thumbRatio =
            (pos.viewportDimension / (pos.viewportDimension + maxScroll))
                .clamp(0.15, 1.0);
        final thumbH = (trackH * thumbRatio).clamp(28.0, trackH);
        final thumbTop = (offset / maxScroll) * (trackH - thumbH);

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            final range = trackH - thumbH;
            if (range <= 0) return;
            final scrollPerPx = maxScroll / range;
            final newOffset =
                (widget.ctrl.offset + details.delta.dy * scrollPerPx)
                    .clamp(0.0, maxScroll);
            widget.ctrl.jumpTo(newOffset);
          },
          child: Container(
            width: 14,
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.25),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: thumbTop),
                child: Container(
                  width: 6,
                  height: thumbH,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
