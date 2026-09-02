import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:music_collection/features/statistics/presentation/widgets/stat_collapsible.dart';

/// An individually collapsible chart inside a section. When collapsed the chart
/// widget is dropped from the tree entirely (un-rendered), preserving RAM.
///
/// [chartId] uniquely identifies the chart's expansion state in the provider.
class ChartCard extends StatelessWidget {
  final String chartId;
  final String title;
  final String? countLabel;
  final Widget child;

  const ChartCard({
    super.key,
    required this.chartId,
    required this.title,
    this.countLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<StatisticsProvider>();
    final expanded = provider.isChartExpanded(chartId);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: StatCollapsible(
        expanded: expanded,
        onToggle: () => provider.toggleChart(chartId),
        contentTopGap: 14,
        header: InkWell(
          onTap: () => provider.toggleChart(chartId),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (countLabel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      countLabel!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
