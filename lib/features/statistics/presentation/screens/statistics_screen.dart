import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:music_collection/features/statistics/presentation/widgets/log_viewer.dart';
import 'package:music_collection/features/statistics/presentation/widgets/statistics_charts_view.dart';
import 'package:music_collection/shared/widgets/error_widget.dart';
import 'package:music_collection/shared/widgets/loading_indicator.dart';

/// The Statistics tab. Loads data on first activation and refreshes each time
/// the tab becomes active again (detected via the nav shell's TickerMode
/// toggle), plus a manual refresh button. No Supabase realtime.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _wasTickerEnabled = true;
  bool _wasLogActive = false;

  @override
  Widget build(BuildContext context) {
    final stats = context.read<StatisticsProvider>();
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    // Refresh each time the tab becomes active (TickerMode flips on).
    if (tickerEnabled && !_wasTickerEnabled) {
      stats.load();
      if (stats.subTab == StatisticsSubTab.log) stats.loadLogs();
    }
    if (!tickerEnabled && _wasTickerEnabled) {
      _wasLogActive = false;
    }
    _wasTickerEnabled = tickerEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: AppColors.electricBlue, size: 22),
            SizedBox(width: 10),
            Text(
              'STATISTICS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, stats, _) {
          // Reload the log once each time the Log sub-tab is (re)entered.
          if (stats.subTab == StatisticsSubTab.log && !_wasLogActive) {
            _wasLogActive = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.read<StatisticsProvider>().subTab ==
                  StatisticsSubTab.log) {
                context.read<StatisticsProvider>().loadLogs();
              }
            });
          }
          return Column(
            children: [
              _SubTabBar(stats: stats),
              Expanded(
                child: switch (stats.subTab) {
                  StatisticsSubTab.charts => _buildCharts(stats),
                  StatisticsSubTab.log => const LogViewer(),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCharts(StatisticsProvider stats) {
    if (stats.isLoading && !stats.loaded) {
      return const AppLoadingIndicator(message: 'Loading statistics...');
    }
    if (stats.loadError != null && !stats.loaded) {
      return AppErrorWidget(
        message: stats.loadError!,
        onRetry: () => stats.load(),
      );
    }
    if (stats.overview == null) {
      return AppErrorWidget(
        message: 'No statistics available yet.',
        onRetry: () => stats.load(),
      );
    }
    return StatisticsChartsView(provider: stats);
  }
}

class _SubTabBar extends StatelessWidget {
  final StatisticsProvider stats;
  const _SubTabBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 13);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<StatisticsSubTab>(
              segments: const [
                ButtonSegment(
                  value: StatisticsSubTab.charts,
                  label: Text('Statistics', style: labelStyle),
                  icon: Icon(Icons.pie_chart_outline, size: 18),
                ),
                ButtonSegment(
                  value: StatisticsSubTab.log,
                  label: Text('Log', style: labelStyle),
                  icon: Icon(Icons.receipt_long_outlined, size: 18),
                ),
              ],
              selected: {stats.subTab},
              showSelectedIcon: false,
              onSelectionChanged: (s) => stats.setSubTab(s.first),
              style: SegmentedButton.styleFrom(
                foregroundColor: const Color(0xFFE8E8E8),
                selectedForegroundColor: const Color(0xFFF5F5F5),
                backgroundColor: Colors.transparent,
                selectedBackgroundColor: const Color(0xFF414141),
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh statistics',
            onPressed: () => stats.load(),
            icon: const Icon(Icons.refresh, color: AppColors.electricBlue),
          ),
        ],
      ),
    );
  }
}

