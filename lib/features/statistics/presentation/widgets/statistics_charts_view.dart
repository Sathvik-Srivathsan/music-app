import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';
import 'package:music_collection/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:music_collection/features/statistics/presentation/widgets/chart_card.dart';
import 'package:music_collection/features/statistics/presentation/widgets/charts/stat_headline_cards.dart';
import 'package:music_collection/features/statistics/presentation/widgets/charts/stat_horizontal_bar_chart.dart';
import 'package:music_collection/features/statistics/presentation/widgets/charts/stat_pie_chart.dart';
import 'package:music_collection/features/statistics/presentation/widgets/charts/stat_value_list.dart';
import 'package:music_collection/features/statistics/presentation/widgets/charts/stat_vertical_bar_chart.dart';
import 'package:music_collection/features/statistics/presentation/widgets/stat_section_card.dart';

/// Builds the seven collapsible chart sections. Reads expansion state and
/// computed data through [provider] (a screen-level Consumer keeps this view
/// in sync when the provider notifies).
class StatisticsChartsView extends StatelessWidget {
  final StatisticsProvider provider;

  const StatisticsChartsView({super.key, required this.provider});

  List<StatBar> _barsFrom(List<EntityCount> items) =>
      [for (final e in items) StatBar(e.name, e.count)];

  @override
  Widget build(BuildContext context) {
    final overview = provider.overview;
    if (overview == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHint(),
        // Overview
        StatSectionCard(
          section: StatisticsSection.overview,
          title: 'Overview',
          icon: Icons.dashboard_outlined,
          subtitle: 'Headline totals at a glance',
          children: [
            StatHeadlineCards(stats: overview),
            ChartCard(
              chartId: 'overview.status',
              title: 'Records by status',
              countLabel: '${overview.totalRecords} records',
              child: StatPieChart(slices: provider.statusSlices),
            ),
          ],
        ),
        // Records
        StatSectionCard(
          section: StatisticsSection.records,
          title: 'Records',
          icon: Icons.album_outlined,
          subtitle:
              '${overview.totalRecords} records by release decade, type and status',
          children: [
            ChartCard(
              chartId: 'records.decade',
              title: 'Records by release decade',
              countLabel: '${overview.recordsWithUnknownYear} unknown year',
              child: StatVerticalBarChart(bars: provider.decadeData.buckets),
            ),
            ChartCard(
              chartId: 'records.type',
              title: 'Records by type',
              child: StatHorizontalBarChart(bars: provider.recordTypeBars),
            ),
          ],
        ),
        // Artists
        StatSectionCard(
          section: StatisticsSection.artists,
          title: 'Artists',
          icon: Icons.person_outline,
          subtitle: '${overview.totalArtists} artists — most recorded',
          children: [
            ChartCard(
              chartId: 'artists.top',
              title: 'Top artists by record count',
              child: StatHorizontalBarChart(bars: _barsFrom(provider.topArtists)),
            ),
          ],
        ),
        // Genres
        StatSectionCard(
          section: StatisticsSection.genres,
          title: 'Genres',
          icon: Icons.category_outlined,
          subtitle: '${overview.totalGenres} genres — most used',
          children: [
            ChartCard(
              chartId: 'genres.top',
              title: 'Top genres by record count',
              child: StatHorizontalBarChart(bars: _barsFrom(provider.topGenres)),
            ),
          ],
        ),
        // Descriptors
        StatSectionCard(
          section: StatisticsSection.descriptors,
          title: 'Descriptors',
          icon: Icons.label_outline,
          subtitle: '${overview.totalDescriptors} descriptors — most used',
          children: [
            ChartCard(
              chartId: 'descriptors.top',
              title: 'Top descriptors by record count',
              child: StatHorizontalBarChart(bars: _barsFrom(provider.topDescriptors)),
            ),
          ],
        ),
        // Streaming
        StatSectionCard(
          section: StatisticsSection.streaming,
          title: 'Streaming',
          icon: Icons.cast_outlined,
          subtitle: '${overview.recordsWithStreaming} records with a service listed',
          children: [
            if (provider.streamingPie != null)
              ChartCard(
                chartId: 'streaming.pie',
                title: 'Records per streaming service',
                countLabel: '${provider.streamingPie!.slices.length} service${provider.streamingPie!.slices.length == 1 ? '' : 's'}',
                child: StatPieChart(slices: provider.streamingPie!.slices),
              ),
          ],
        ),
        // Relationships
        StatSectionCard(
          section: StatisticsSection.relationships,
          title: 'Relationships',
          icon: Icons.account_tree_outlined,
          subtitle: 'Taxonomy links and multi-entity records',
          children: [
            ChartCard(
              chartId: 'relationships.list',
              title: 'Relationship summary',
              child: StatValueList(items: provider.relationships),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Charts only render while expanded. Tap a section or chart '
              'header to open or close it.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
