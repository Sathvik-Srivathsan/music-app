import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';

/// A simple label -> count list row used for relationship summaries.
class StatValueList extends StatelessWidget {
  final List<EntityCount> items;

  const StatValueList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'No data',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: i < items.length - 1
                  ? const Border(
                      bottom: BorderSide(color: AppColors.grid, width: 0.5),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    items[i].name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${items[i].count}',
                  style: TextStyle(
                    color: AppColors.chartPalette[i % AppColors.chartPalette.length],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
