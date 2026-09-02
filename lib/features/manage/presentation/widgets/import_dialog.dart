import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/features/manage/presentation/widgets/import_rectification_dialog.dart';
import 'package:music_collection/features/manage/presentation/widgets/import_record_type_dialog.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:provider/provider.dart';

/// Unified import dialog.
///
/// A single popup that never closes on its own. The body morphs through:
///   pass1 (progress) -> rectification (queues) -> pass2 (progress) -> summary.
class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ImportDialog(),
    );
  }

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ManageProvider>(
      builder: (context, manage, _) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: _buildTitle(manage),
          content: SizedBox(
            width: 680,
            child: _buildBody(manage, context),
          ),
          actions: _buildActions(manage, context),
        );
      },
    );
  }

  // ---- Title ----

  Widget _buildTitle(ManageProvider manage) {
    String text;
    switch (manage.importPhase) {
      case ImportPhase.reading:
        text = 'Reading File';
        break;
      case ImportPhase.validation:
        text = 'Review Import';
        break;
      case ImportPhase.pass1:
        text = 'Validating';
        break;
      case ImportPhase.rectification:
        text = 'Review Issues';
        break;
      case ImportPhase.pass2:
        text = 'Importing';
        break;
      case ImportPhase.summary:
        text = 'Import Complete';
        break;
      case ImportPhase.idle:
        text = manage.importError != null ? 'Import Failed' : 'Import';
        break;
    }
    return Row(
      children: [
        const Icon(Icons.import_export,
            size: 20, color: AppColors.electricBlue),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  // ---- Body ----

  Widget _buildBody(ManageProvider manage, BuildContext context) {
    switch (manage.importPhase) {
      case ImportPhase.reading:
        return _buildProgressBody('Reading and validating the file…');
      case ImportPhase.validation:
        return _buildReviewBody(manage);
      case ImportPhase.pass1:
        return _buildProgressBody('Checking the file…');
      case ImportPhase.pass2:
        return _buildProgressBody('Writing to the database…');
      case ImportPhase.rectification:
        return _buildRectificationBody(manage, context);
      case ImportPhase.summary:
        return _buildSummaryBody(manage, context);
      case ImportPhase.idle:
        if (manage.importError != null) {
          return _buildErrorBody(manage.importError!);
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorBody(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBody(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  // ---- Review body (file loaded, before import) ----

  Widget _buildReviewBody(ManageProvider manage) {
    final skipped = manage.importEmptyNames +
        manage.importDuplicatesInFile +
        manage.importDuplicatesVsDb;
    final broken = manage.importBrokenParents;
    final hasIssue = broken > 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(manage.importFileName ?? '',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              Text('${manage.importTotal} rows',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(80),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: hasIssue ? AppColors.warning : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Validation Summary',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _buildReviewRow('Total rows', '${manage.importTotal}'),
                _buildReviewRow(
                    'New (will import)', '${manage.importValid}',
                    valueColor: manage.importValid > 0
                        ? AppColors.electricBlue
                        : AppColors.textSecondary),
                if (skipped > 0) ...[
                  const SizedBox(height: 4),
                  _buildReviewRow('Skipped', '$skipped'),
                  if (manage.importEmptyNames > 0)
                    _buildReviewRow(
                        '', 'Empty names: ${manage.importEmptyNames}',
                        indent: true),
                  if (manage.importDuplicatesInFile > 0)
                    _buildReviewRow(
                        '',
                        'Duplicates in file: ${manage.importDuplicatesInFile}',
                        indent: true),
                  if (manage.importDuplicatesVsDb > 0)
                    _buildReviewRow(
                        '',
                        'Already in database: ${manage.importDuplicatesVsDb}',
                        indent: true),
                ],
                if (broken > 0) ...[
                  const SizedBox(height: 4),
                  _buildReviewRow('Broken parent refs', '$broken',
                      valueColor: AppColors.warning),
                ],
              ],
            ),
          ),
          if (manage.importValid <= 0) ...[
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No new rows to import — every row is empty, duplicated in the file, or already in the database.',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildReviewRow(String label, String value,
      {Color? valueColor, bool indent = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2, left: indent ? 12 : 0),
      child: Row(
        children: [
          if (label.isNotEmpty) ...[
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
            const SizedBox(width: 12),
          ],
          Text(value,
              style: TextStyle(
                color: valueColor ?? AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  // ---- Actions ----

  List<Widget> _buildActions(ManageProvider manage, BuildContext context) {
    switch (manage.importPhase) {
      case ImportPhase.validation:
        return [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: manage.importValid > 0
                  ? AppColors.electricBlue
                  : AppColors.surface,
              foregroundColor: manage.importValid > 0
                  ? AppColors.background
                  : AppColors.textHint,
              side: BorderSide(
                  color: manage.importValid > 0
                      ? AppColors.electricBlue
                      : AppColors.border),
            ),
            onPressed: manage.importValid > 0
                ? () => manage.startImport()
                : null,
            child: const Text('Import', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _cancelAndPop(context),
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ];
      case ImportPhase.pass1:
      case ImportPhase.reading:
        return [
          TextButton(
            onPressed: () {
              manage.cancelImport();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ];
      case ImportPhase.summary:
        return [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
            ),
            onPressed: () {
              manage.dismissDialog();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Close',
                style: TextStyle(color: AppColors.background, fontSize: 13)),
          ),
        ];
      case ImportPhase.rectification:
      case ImportPhase.pass2:
        return const [];
      case ImportPhase.idle:
        if (manage.importError != null) {
          return [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
              ),
              onPressed: () {
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Close',
                  style:
                      TextStyle(color: AppColors.background, fontSize: 13)),
            ),
          ];
        }
        return const [];
    }
  }

  // ---- Rectification body ----

  Widget _buildRectificationBody(ManageProvider manage, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (manage.dateAddedViolation) ...[
            _buildDateAddedViolationSection(manage, context),
          ] else if (manage.parentColumnGate) ...[
            _buildParentColumnGateSection(manage, context),
          ] else if (manage.activeWarningQueue != null &&
              !manage.allRectified) ...[
            _buildActiveWarningSection(manage, context),
          ] else ...[
            const SizedBox(height: 40),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveWarningSection(
      ManageProvider manage, BuildContext context) {
    final queue = manage.activeWarningQueue;
    if (queue == null) return const SizedBox.shrink();

    switch (queue) {
      case 'recordTypeInvalid':
        return _buildRecordTypeInvalidSection(manage, context);
      case 'artistMismatch':
        return _buildArtistMismatchSection(manage, context);
      case 'streaming':
        return _buildStreamingWarningSection(manage, context);
      case 'separator':
        return _buildSeparatorWarningSection(manage, context);
      case 'dateFormat':
        return _buildDateFormatWarningSection(manage, context);
      case 'genreMismatch':
        return _buildGenreMismatchSection(manage, context);
      case 'descMismatch':
        return _buildDescMismatchSection(manage, context);
      case 'parentNotFound':
        return _buildParentWarningSection(manage, context);
      default:
        return const SizedBox.shrink();
    }
  }

  void _cancelAndPop(BuildContext context) {
    context.read<ManageProvider>().cancelImport();
    if (context.mounted) Navigator.of(context).pop();
  }

  // ---- Warning sections ----

  Widget _buildParentWarningSection(
      ManageProvider manage, BuildContext context) {
    final current = manage.parentNotFoundIndex;
    final total = manage.parentNotFoundTotal;
    final remaining = total - current;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Parent Warnings — $remaining remaining',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (current < total) ...[
            Text(
              'Parent "${manage.parentNotFoundQueue[current].parentName}" for '
              '"${manage.parentNotFoundQueue[current].childName}" was not found.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                  ),
                  onPressed: () async {
                    final result = await ImportRectificationDialog.show(
                      context,
                      message: 'Parent not found. Select a replacement or leave blank for root.',
                      currentValue: manage.parentNotFoundQueue[current].parentName,
                      allGenres: manage.rawGenres.map((e) => e.entity).toList(),
                      allDescriptors:
                          manage.rawDescriptors.map((e) => e.entity).toList(),
                      allArtists: manage.rawArtists.map((e) => e.entity).toList(),
                      isGenre: manage.importEntityTypeSelection ==
                          ImportEntityType.genres,
                      isArtist: false,
                      fuzzyMatch: (q, e) {
                        if (e is Genre) {
                          return CsvUtils.calculateSimilarity(q, e.genreName);
                        }
                        if (e is Descriptor) {
                          return CsvUtils.calculateSimilarity(q, e.descriptorName);
                        }
                        return 0.0;
                      },
                    );
                    if (result == null) return;
                    if (!context.mounted) return;
                    switch (result.action) {
                      case ImportRectificationAction.confirm:
                        manage.rectifyParentNotFound(result.selectedId);
                        break;
                      case ImportRectificationAction.skipTuple:
                        manage.skipParentNotFoundTuple();
                        break;
                      case ImportRectificationAction.cancelImport:
                        _cancelAndPop(context);
                        break;
                    }
                  },
                  child: const Text('Rectify',
                      style: TextStyle(
                          color: AppColors.background, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () => manage.skipParentNotFoundTuple(),
                  child: const Text('Skip Tuple',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _cancelAndPop(context),
                  child: const Text('Cancel Import',
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordTypeInvalidSection(
      ManageProvider manage, BuildContext context) {
    final current = manage.recordTypeInvalidIndex;
    final total = manage.recordTypeInvalidQueue.length;
    final remaining = total - current;

    return _buildQueueSection(
      title: 'Record Type Invalid — $remaining remaining',
      body: current < total
          ? 'Record "${manage.recordTypeInvalidQueue[current].recordName}" has '
              'type "${manage.recordTypeInvalidQueue[current].rawValue}" which '
              'is not a valid record type.'
          : '',
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
          ),
          onPressed: () => manage.proceedRecordTypeInvalid(),
          child: const Text('Proceed (Blank Cell)',
              style: TextStyle(color: AppColors.background, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () async {
            final chosen = await ImportRecordTypeDialog.show(
              context,
              message: 'Invalid record type. Choose a valid record type.',
              currentValue: manage.recordTypeInvalidQueue[current].rawValue,
            );
            if (chosen == null || !context.mounted) return;
            manage.rectifyRecordTypeInvalid(chosen);
          },
          child: const Text('Rectify', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _cancelAndPop(context),
          child: const Text('Cancel Import',
              style: TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildArtistMismatchSection(
      ManageProvider manage, BuildContext context) {
    final current = manage.artistMismatchIndex;
    final total = manage.artistMismatchQueue.length;
    final remaining = total - current;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Artist Mismatch — $remaining remaining',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (current < total) ...[
            Text(
              'Record "${manage.artistMismatchQueue[current].recordName}" references '
              'artist "${manage.artistMismatchQueue[current].csvArtistName}" which '
              'does not exist in the database.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                  ),
                  onPressed: () => manage.proceedArtistMismatch(),
                  child: const Text('Proceed (Blank Cell)',
                      style: TextStyle(
                          color: AppColors.background, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () => manage.autoFixArtistMismatch(),
                  child: const Text('Auto-Fix', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                  ),
                  onPressed: () async {
                    final result = await ImportRectificationDialog.show(
                      context,
                      message: 'Artist not found. Select a replacement from the database.',
                      currentValue: manage.artistMismatchQueue[current].csvArtistName,
                      allGenres:
                          manage.rawGenres.map((e) => e.entity).toList(),
                      allDescriptors:
                          manage.rawDescriptors.map((e) => e.entity).toList(),
                      allArtists: manage.rawArtists.map((e) => e.entity).toList(),
                      isGenre: false,
                      isArtist: true,
                      fuzzyMatch: (q, e) {
                        if (e is Artist) {
                          return CsvUtils.calculateSimilarity(q, e.artistName);
                        }
                        return 0.0;
                      },
                    );
                    if (result == null) return;
                    if (!context.mounted) return;
                    switch (result.action) {
                      case ImportRectificationAction.confirm:
                        manage.rectifyArtistMismatch(result.selectedId);
                        break;
                      case ImportRectificationAction.skipTuple:
                        manage.skipArtistMismatchTuple();
                        break;
                      case ImportRectificationAction.cancelImport:
                        _cancelAndPop(context);
                        break;
                    }
                  },
                  child: const Text('Rectify',
                      style: TextStyle(
                          color: AppColors.background, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () => manage.skipArtistMismatchTuple(),
                  child: const Text('Skip Tuple',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _cancelAndPop(context),
                  child: const Text('Cancel Import',
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingWarningSection(
      ManageProvider manage, BuildContext context) {
    final current = manage.streamingWarningIndex;
    final total = manage.streamingWarningQueue.length;
    final remaining = total - current;

    return _buildQueueSection(
      title: 'Streaming Warning — $remaining remaining',
      body: current < total
          ? 'Record "${manage.streamingWarningQueue[current].recordName}" has '
              'unrecognized streaming value(s): '
              '${manage.streamingWarningQueue[current].unrecognizedNames.join(", ")}.'
          : '',
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
          ),
          onPressed: () => manage.proceedStreamingWarning(),
          child: const Text('Proceed (Blank the Cells)',
              style: TextStyle(color: AppColors.background, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.autoFixStreamingWarning(),
          child: const Text('Auto-Fix', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.skipStreamingWarningTuple(),
          child: const Text('Skip Tuple', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _cancelAndPop(context),
          child: const Text('Cancel Import',
              style: TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildGenreMismatchSection(
      ManageProvider manage, BuildContext context) {
    final current = manage.genreMismatchIndex;
    final total = manage.genreMismatchQueue.length;
    final remaining = total - current;

    return _buildQueueSection(
      title: 'Genre Mismatch — $remaining remaining',
      body: current < total
          ? 'Record "${manage.genreMismatchQueue[current].recordName}" has '
              'unrecognized genre value(s): '
              '${manage.genreMismatchQueue[current].invalidGenres.join(", ")}.'
          : '',
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
          ),
          onPressed: () => manage.proceedGenreMismatch(),
          child: const Text('Proceed (Blank Cell)',
              style: TextStyle(color: AppColors.background, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.autoFixGenreMismatch(),
          child: const Text('Auto-Fix', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.skipGenreMismatchTuple(),
          child: const Text('Skip Tuple', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _cancelAndPop(context),
          child: const Text('Cancel Import',
              style: TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDescMismatchSection(ManageProvider manage, BuildContext context) {
    final current = manage.descMismatchIndex;
    final total = manage.descMismatchQueue.length;
    final remaining = total - current;

    return _buildQueueSection(
      title: 'Descriptor Mismatch — $remaining remaining',
      body: current < total
          ? 'Record "${manage.descMismatchQueue[current].recordName}" has '
              'unrecognized descriptor value(s): '
              '${manage.descMismatchQueue[current].invalidDescriptors.join(", ")}.'
          : '',
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
          ),
          onPressed: () => manage.proceedDescMismatch(),
          child: const Text('Proceed (Blank Cell)',
              style: TextStyle(color: AppColors.background, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.autoFixDescMismatch(),
          child: const Text('Auto-Fix', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.skipDescMismatchTuple(),
          child: const Text('Skip Tuple', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _cancelAndPop(context),
          child: const Text('Cancel Import',
              style: TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildSeparatorWarningSection(
      ManageProvider manage, BuildContext context) {
    final current = manage.separatorWarningIndex;
    final total = manage.separatorWarningQueue.length;
    final remaining = total - current;

    return _buildQueueSection(
      title: 'Separator Warning — $remaining remaining',
      body: current < total
          ? 'Record "${manage.separatorWarningQueue[current].recordName}" has '
              'a mismatch in "${manage.separatorWarningQueue[current].fieldName}": '
              '${manage.separatorWarningQueue[current].rawValue}.'
          : '',
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
          ),
          onPressed: () => manage.proceedSeparatorWarning(),
          child: const Text('Proceed (Blank the Cells)',
              style: TextStyle(color: AppColors.background, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.skipSeparatorWarningTuple(),
          child: const Text('Skip Tuple', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _cancelAndPop(context),
          child: const Text('Cancel Import',
              style: TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDateFormatWarningSection(
      ManageProvider manage, BuildContext context) {
    final current = manage.dateFormatWarningIndex;
    final total = manage.dateFormatWarningQueue.length;
    final remaining = total - current;

    return _buildQueueSection(
      title: 'Date Format Warning — $remaining remaining',
      body: current < total
          ? 'Record "${manage.dateFormatWarningQueue[current].recordName}" has '
              'invalid date in "${manage.dateFormatWarningQueue[current].fieldName}": '
              '"${manage.dateFormatWarningQueue[current].rawValue}".'
          : '',
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
          ),
          onPressed: () => manage.proceedDateFormatWarning(),
          child: const Text('Proceed (Blank the Cells)',
              style: TextStyle(color: AppColors.background, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () => manage.skipDateFormatWarningTuple(),
          child: const Text('Skip Tuple', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _cancelAndPop(context),
          child: const Text('Cancel Import',
              style: TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDateAddedViolationSection(
      ManageProvider manage, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'date_added Column Detected',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This CSV contains a "date_added" column which is not part of the '
            'expected format. The date_added field is system-managed and cannot '
            'be imported directly.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                ),
                onPressed: () async {
                  manage.proceedDateAddedViolation();
                  await manage.startImport();
                },
                child: const Text('Proceed (date = today)',
                    style: TextStyle(
                        color: AppColors.background, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _cancelAndPop(context),
                child: const Text('Cancel Import',
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentColumnGateSection(
      ManageProvider manage, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Missing Parent Column',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This file has no parent column, so every entry will be imported '
            'as a root entry.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                ),
                onPressed: () => manage.proceedParentColumnGate(),
                child: const Text('Proceed (Import as Root Entries)',
                    style:
                        TextStyle(color: AppColors.background, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _cancelAndPop(context),
                child: const Text('Cancel Import',
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSection({
    required String title,
    required String body,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Row(children: children),
        ],
      ),
    );
  }

  // ---- Summary body ----

  Widget _buildSummaryBody(ManageProvider manage, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (manage.importedRecords.isNotEmpty) ...[
            _buildSummarySection(
              title: 'Successfully Imported',
              count: manage.importedRecords.length,
              children: manage.importedRecords
                  .map((r) => _buildSummaryLine(
                        'Name: ${r.recordName}',
                        r.artists.isEmpty ? null : 'Artists: ${r.artists}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.parentColumnMissing) ...[
            _buildSummarySection(
              title: 'Missing Parent Column',
              children: [
                _buildSummaryLine(
                    'The file had no parent column, so every entry was imported as a root entry.',
                    null),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (manage.dateAddedResolved) ...[
            _buildSummarySection(
              title: 'date_added Column Resolved',
              children: [
                _buildSummaryLine(
                    'The date_added column was replaced with today\'s date.',
                    null),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (manage.recordTypeInvalidQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Record Type Invalid', manage.recordTypeInvalidQueue, (e) => e.skipped),
              count: manage.recordTypeInvalidQueue.length,
              children: manage.recordTypeInvalidQueue
                  .map((e) => _buildSummaryLine(
                        'Record: ${e.recordName}',
                        e.skipped
                            ? 'Skipped — not imported'
                            : 'Type: ${e.rawValue}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.artistMismatchQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Artist Mismatches', manage.artistMismatchQueue, (e) => e.skipped),
              count: manage.artistMismatchQueue.length,
              children: manage.artistMismatchQueue
                  .map((e) => _buildSummaryLine(
                        'Record: ${e.recordName}',
                        e.skipped ? 'Skipped — not imported' : 'Artist: ${e.csvArtistName}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.streamingWarningQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Streaming Warnings', manage.streamingWarningQueue, (e) => e.skipped),
              count: manage.streamingWarningQueue.length,
              children: manage.streamingWarningQueue
                  .map((e) => _buildSummaryLine(
                        'Record: ${e.recordName}',
                        e.skipped
                            ? 'Skipped — not imported'
                            : 'Unrecognized: ${e.unrecognizedNames.join(", ")}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.separatorWarningQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Separator Warnings', manage.separatorWarningQueue, (e) => e.skipped),
              count: manage.separatorWarningQueue.length,
              children: manage.separatorWarningQueue
                  .map((e) => _buildSummaryLine(
                        'Record: ${e.recordName}',
                        e.skipped
                            ? 'Skipped — not imported'
                            : '${e.fieldName}: ${e.rawValue}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.dateFormatWarningQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Date Format Warnings', manage.dateFormatWarningQueue, (e) => e.skipped),
              count: manage.dateFormatWarningQueue.length,
              children: manage.dateFormatWarningQueue
                  .map((e) => _buildSummaryLine(
                        'Record: ${e.recordName}',
                        e.skipped
                            ? 'Skipped — not imported'
                            : '${e.fieldName}: ${e.rawValue}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.genreMismatchQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Genre Mismatches', manage.genreMismatchQueue, (e) => e.skipped),
              count: manage.genreMismatchQueue.length,
              children: manage.genreMismatchQueue
                  .map((e) => _buildSummaryLine(
                        'Record: ${e.recordName}',
                        e.skipped
                            ? 'Skipped — not imported'
                            : 'Invalid: ${e.invalidGenres.join(", ")}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.descMismatchQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Descriptor Mismatches', manage.descMismatchQueue, (e) => e.skipped),
              count: manage.descMismatchQueue.length,
              children: manage.descMismatchQueue
                  .map((e) => _buildSummaryLine(
                        'Record: ${e.recordName}',
                        e.skipped
                            ? 'Skipped — not imported'
                            : 'Invalid: ${e.invalidDescriptors.join(", ")}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.parentNotFoundQueue.isNotEmpty) ...[
            _buildSummarySection(
              title: _resolvedSkippedTitle(
                  'Parent Not Found', manage.parentNotFoundQueue, (e) => e.skipped),
              count: manage.parentNotFoundQueue.length,
              children: manage.parentNotFoundQueue
                  .map((e) => _buildSummaryLine(
                        'Name: ${e.childName}',
                        e.skipped
                            ? 'Skipped — not imported'
                            : e.parentName.isEmpty
                                ? null
                                : 'Parent: ${e.parentName}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.skippedRecords.isNotEmpty) ...[
            _buildSummarySection(
              title: 'Records Skipped',
              count: manage.skippedRecords.length,
              children: manage.skippedRecords
                  .map((e) => _buildSummaryLine(
                        'Name: ${e.recordName}',
                        'Reason: ${e.reason}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (manage.statusWarningCount > 0) ...[
            _buildSummarySection(
              title: 'Status Defaulted to Active',
              count: manage.statusWarningCount,
              children: [
                _buildSummaryLine(
                    '${manage.statusWarningCount} record(s) had an unrecognized status value and were set to Active.',
                    null),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (manage.extraUrlRows > 0) ...[
            _buildSummarySection(
              title: 'Streaming / URL — extra URLs ignored',
              count: manage.extraUrlRows,
              children: [
                _buildSummaryLine(
                    '${manage.extraUrlRows} record(s) had more URLs than streaming names. '
                    'The extra URLs were ignored.',
                    null),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (manage.importedRecords.isEmpty &&
              manage.parentColumnMissing == false &&
              manage.dateAddedResolved == false &&
              manage.recordTypeInvalidQueue.isEmpty &&
              manage.artistMismatchQueue.isEmpty &&
              manage.streamingWarningQueue.isEmpty &&
              manage.separatorWarningQueue.isEmpty &&
              manage.dateFormatWarningQueue.isEmpty &&
              manage.genreMismatchQueue.isEmpty &&
              manage.descMismatchQueue.isEmpty &&
              manage.parentNotFoundQueue.isEmpty &&
              manage.skippedRecords.isEmpty &&
              manage.statusWarningCount == 0 &&
              manage.extraUrlRows == 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No records were imported.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _resolvedSkippedTitle<T>(
      String base, List<T> items, bool Function(T) isSkipped) {
    var resolved = 0;
    var skipped = 0;
    for (final item in items) {
      if (isSkipped(item)) {
        skipped++;
      } else {
        resolved++;
      }
    }
    if (skipped == 0) return '$base Resolved';
    if (resolved == 0) return '$base Skipped';
    return '$base Resolved · Skipped';
  }

  Widget _buildSummarySection({
    required String title,
    int? count,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, right: 4, bottom: 8),
visualDensity: VisualDensity.compact,
      dense: true,
      initiallyExpanded: false,
      title: Text(
        count != null ? '$title ($count)' : title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Expand to view details',
              style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_downward,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
      children: children,
      ),
    );
  }

  static Widget _buildSummaryLine(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ),
          if (value != null && value.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}