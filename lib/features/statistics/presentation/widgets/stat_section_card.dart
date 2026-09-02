import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:music_collection/features/statistics/presentation/widgets/stat_collapsible.dart';

/// A collapsible subsection of the Statistics tab. When collapsed it un-renders
/// every chart inside (the whole body leaves the tree), which frees the memory
/// held by any rendered graphs regardless of their individual toggles.
class StatSectionCard extends StatelessWidget {
  final StatisticsSection section;
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> children;

  const StatSectionCard({
    super.key,
    required this.section,
    required this.title,
    required this.icon,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = _isExpanded(context, section);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: expanded ? AppColors.electricBlue : AppColors.border,
        ),
      ),
      child: StatCollapsible(
        expanded: expanded,
        onToggle: () => _toggle(context, section),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        header: _header(context, expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool expanded) {
    return InkWell(
      onTap: () => _toggle(context, section),
      hoverColor: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.electricBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

bool _isExpanded(BuildContext context, StatisticsSection section) =>
    context.read<StatisticsProvider>().isSectionExpanded(section);

void _toggle(BuildContext context, StatisticsSection section) =>
    context.read<StatisticsProvider>().toggleSection(section);
