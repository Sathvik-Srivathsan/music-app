import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';

/// A CVD-safe fl_chart pie with a compact SVG-less legend underneath. Renders
/// the slices exactly as provided (already capped to 6 by the engine).
class StatPieChart extends StatelessWidget {
  final List<StatSlice> slices;
  final bool showPercent;

  const StatPieChart({
    super.key,
    required this.slices,
    this.showPercent = true,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (s, x) => s + x.value);
    if (total == 0 || slices.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('No data',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < slices.length; i++)
                  PieChartSectionData(
                    value: slices[i].value.toDouble(),
                    color: AppColors.chartPalette[i % AppColors.chartPalette.length],
                    radius: 48,
                    title: showPercent
                        ? '${(slices[i].value / total * 100).toStringAsFixed(1)}%'
                        : '${slices[i].value}',
                    titleStyle: const TextStyle(
                      color: AppColors.background,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  ),
              ],
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Legend(slices: slices, total: total),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final List<StatSlice> slices;
  final int total;
  const _Legend({required this.slices, required this.total});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        for (var i = 0; i < slices.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.chartPalette[i % AppColors.chartPalette.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${slices[i].label} (${slices[i].value})',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }
}
