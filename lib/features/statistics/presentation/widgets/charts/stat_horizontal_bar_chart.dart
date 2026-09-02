import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';

/// A horizontal bar list ideal for top-k results with long labels. Each row is
/// a full-width label plus a fractional-width bar at ~90% opacity with its
/// count value printed on every bar. Pure non-fl_chart rendering keeps long
/// category names fully readable and reliably attached to the correct bar.
class StatHorizontalBarChart extends StatelessWidget {
  final List<StatBar> bars;

  const StatHorizontalBarChart({super.key, required this.bars});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('No data', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    final maxVal = bars.map((b) => b.value).fold<int>(0, math.max);
    final safeMax = maxVal == 0 ? 1 : maxVal;
    return Column(
      children: [
        for (var i = 0; i < bars.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bars[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(
                              height: 16,
                              color: AppColors.grid.withValues(alpha: 0.3),
                            ),
                            FractionallySizedBox(
                              widthFactor: bars[i].value / safeMax,
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors
                                      .chartPalette[i % AppColors.chartPalette.length]
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 54,
                      child: Text(
                        '${bars[i].value}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
