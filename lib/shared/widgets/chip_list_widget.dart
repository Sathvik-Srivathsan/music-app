import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';

class ChipListWidget<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T) onRemove;
  final bool reorderable;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const ChipListWidget({
    super.key,
    required this.items,
    required this.itemToString,
    required this.onRemove,
    this.reorderable = false,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    if (reorderable && onReorder != null) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        onReorder: onReorder!,
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildChip(context, item, index);
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        return _buildChip(context, entry.value, entry.key);
      }).toList(),
    );
  }

  Widget _buildChip(BuildContext context, T item, int index) {
    return Chip(
      label: Text(
        itemToString(item),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onDeleted: () => onRemove(item),
      avatar: reorderable
          ? const Icon(
              Icons.drag_handle,
              size: 16,
              color: AppColors.textSecondary,
            )
          : null,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
