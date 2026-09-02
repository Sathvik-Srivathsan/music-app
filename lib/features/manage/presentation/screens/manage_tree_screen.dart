import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/manage/domain/models/tree_node.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';

class ManageTreeScreen extends StatelessWidget {
  final String title;
  final List<TreeNode>? nodes;
  final Set<int> expandedIds;
  final bool isLoading;
  final String? error;
  final ValueChanged<int> onToggle;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  const ManageTreeScreen({
    super.key,
    required this.title,
    required this.nodes,
    required this.expandedIds,
    required this.isLoading,
    required this.error,
    required this.onToggle,
    required this.onExpandAll,
    required this.onCollapseAll,
    required this.onBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to Manage'),
                onPressed: onBack,
              ),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              InfoTip(
                  body: title == 'Genre Tree'
                      ? 'This tree shows every genre and its hierarchy.\n\nClick any genre with children to expand or collapse its branch. Use "Expand All" to open every branch at once, or "Collapse All" to close them.\n\nNumbers in badges show how many descendants each genre has.'
                      : 'This tree shows every descriptor and its hierarchy.\n\nClick any descriptor with children to expand or collapse its branch. Use "Expand All" to open every branch at once, or "Collapse All" to close them.\n\nNumbers in badges show how many descendants each descriptor has.'),
              const Spacer(),
              const SizedBox(width: 120),
            ],
          ),
        ),
        const Divider(color: AppColors.border, height: 1),

        // Action bar
        if (!isLoading && error == null && nodes != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.electricBlue,
                    side: const BorderSide(color: AppColors.electricBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onExpandAll,
                  child: const Text('Expand All', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.electricBlue,
                    side: const BorderSide(color: AppColors.electricBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onCollapseAll,
                  child: const Text('Collapse All', style: TextStyle(fontSize: 13)),
                ),
                const Spacer(),
                Text('${nodes!.length} root entries',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
        ],

        // Tree content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.electricBlue),
            SizedBox(height: 16),
            Text('Loading tree...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    if (nodes == null || nodes!.isEmpty) {
      return const Center(
        child: Text('No hierarchy entries found',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: nodes!.length,
      itemBuilder: (context, index) => _buildNode(nodes![index], 0),
    );
  }

  Widget _buildNode(TreeNode node, int depth) {
    final isExpanded = expandedIds.contains(node.id);
    final hasChildren = node.hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren ? () => onToggle(node.id) : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.0 + depth * 20.0, 6, 24, 6),
            child: Row(
              children: [
                // Arrow
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 18,
                    color: AppColors.textSecondary,
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 4),
                Text(
                  node.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (node.descendantCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${node.descendantCount}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Children
        if (isExpanded && hasChildren)
          ...node.children.map((child) => _buildNode(child, depth + 1)),
      ],
    );
  }
}
