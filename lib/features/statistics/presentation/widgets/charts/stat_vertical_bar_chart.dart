import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';

/// Vertical fl_chart bar for short-category distributions (e.g. decades with
/// labels like "1960s"). Each bar at ~90% opacity. Single series, so no dash
/// distinction needed.
class StatVerticalBarChart extends StatelessWidget {
  final List<StatBar> bars;

  const StatVerticalBarChart({super.key, required this.bars});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('No data', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    final maxVal = bars.map((b) => b.value).fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;
    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMax.toDouble() * 1.15,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                '${bars[groupIndex].label}: ${rod.toY.toInt()}',
                const TextStyle(color: AppColors.background, fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) => _labelTitle(
                  value.toInt(),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => _numberTitle(value),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.grid, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].value.toDouble(),
                    width: 26,
                    color: AppColors
                        .chartPalette[i % AppColors.chartPalette.length]
                        .withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _labelTitle(int index) {
    if (index < 0 || index >= bars.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        bars[index].label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }

  Widget _numberTitle(double value) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        value.toInt() <= 0 ? '' : '${value.toInt()}',
        textAlign: TextAlign.right,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }
}
