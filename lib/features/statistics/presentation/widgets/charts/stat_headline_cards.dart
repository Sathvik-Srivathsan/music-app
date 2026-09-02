import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';

/// A row of lightweight headline 'stat cards' for the Overview section.
/// These are plain text tiles (no chart), so they can always render even when
/// the surrounding section/chart collapsibles are closed.
class StatHeadlineCards extends StatelessWidget {
  final OverviewStats stats;
  const StatHeadlineCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = <(String, int, Color)>[
      ('Records', stats.totalRecords, AppColors.electricBlue),
      ('Active', stats.activeRecords, AppColors.active),
      ('Finished', stats.finishedRecords, AppColors.finished),
      ('Artists', stats.totalArtists, AppColors.vividOrange),
      ('Genres', stats.totalGenres, AppColors.teal),
      ('Descriptors', stats.totalDescriptors, AppColors.lavenderPurple),
      ('Streaming links', stats.totalStreamingLinks, AppColors.magentaRose),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width > 900
            ? 4
            : width > 560
                ? 3
                : 2;
        final itemW = (width - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, value, color) in items)
              Container(
                width: itemW,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
