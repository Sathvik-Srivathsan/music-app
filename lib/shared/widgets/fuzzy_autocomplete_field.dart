import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';

class FuzzyAutocompleteField<T extends Object> extends StatefulWidget {
  final String labelText;
  final List<T> allItems;
  final String Function(T) itemToString;
  final double Function(String, T) similarityFn;
  final void Function(T) onSelected;
  final VoidCallback onCreateNew;
  final void Function(String text)? onTextSubmitted;
  final String createNewLabel;
  final Key? resetKey;

  const FuzzyAutocompleteField({
    super.key,
    this.resetKey,
    required this.labelText,
    required this.allItems,
    required this.itemToString,
    required this.similarityFn,
    required this.onSelected,
    required this.onCreateNew,
    this.onTextSubmitted,
    this.createNewLabel = '+ Create New',
  });

  @override
  State<FuzzyAutocompleteField<T>> createState() =>
      _FuzzyAutocompleteFieldState<T>();
}

class _FuzzyAutocompleteFieldState<T extends Object>
    extends State<FuzzyAutocompleteField<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showDropdown = true);
      } else {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showDropdown = false);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(FuzzyAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) {
      _controller.clear();
      _focusNode.unfocus();
      setState(() => _showDropdown = false);
    }
  }

  List<T> _getFilteredItems(String query) {
    if (query.isEmpty) return widget.allItems;
    return widget.allItems
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

  void _selectItem(T item) {
    widget.onSelected(item);
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _showDropdown = false);
  }

  void _handleTextSubmitted() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (widget.onTextSubmitted != null) {
      widget.onTextSubmitted!(text);
    }
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _showDropdown = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems(_controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _handleTextSubmitted(),
          decoration: InputDecoration(
            labelText: widget.labelText,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppColors.electricBlue, size: 20),
                  tooltip: 'Confirm',
                  onPressed: _handleTextSubmitted,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.teal, size: 20),
                  tooltip: widget.createNewLabel,
                  onPressed: widget.onCreateNew,
                ),
              ],
            ),
          ),
        ),
        if (_showDropdown && filteredItems.isNotEmpty)
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
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final option = filteredItems[index];
                    return InkWell(
                      onTap: () => _selectItem(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          widget.itemToString(option),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
