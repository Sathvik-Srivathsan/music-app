import 'dart:convert' show utf8;
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/utils/web_download.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/features/manage/presentation/widgets/import_dialog.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';
import 'package:provider/provider.dart';

class ManageImportExportScreen extends StatelessWidget {
  const ManageImportExportScreen({super.key});

  void _downloadCsv(String csvString, String fileName) {
    final bytes = utf8.encode(csvString);
    downloadCsvBytes(bytes, fileName);
  }

  void _downloadFormatCsv(ImportEntityType type) {
    _downloadCsv(_headerRow(type), _getExportFileName(type));
  }

  String _headerRow(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.artists:
        return 'name';
      case ImportEntityType.genres:
        return 'name,parent';
      case ImportEntityType.descriptors:
        return 'name,parent';
      case ImportEntityType.fullDatabase:
        return 'record_name,artists,genres,descriptors,release_date,type,'
            'streaming,URL,comments,status';
    }
  }

  Future<void> _pickCsvFile(BuildContext context, ManageProvider manage) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      String? csvString;
      if (file.bytes != null) {
        csvString = utf8.decode(file.bytes!);
      } else if (!kIsWeb && file.path != null) {
        csvString = await io.File(file.path!).readAsString();
      }
      if (csvString == null) {
        manage.setImportError(
            'Could not read the selected file. Please select a CSV file and try again.');
        return;
      }
      if (csvString.startsWith('\uFEFF')) {
        csvString = csvString.substring(1);
      }
      manage.beginImportRead();
      if (context.mounted) {
        ImportDialog.show(context);
      }
      await manage.loadImportFile(csvString, file.name);
    } catch (e) {
      manage.setImportError('Could not read the selected file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManageProvider>(
      builder: (context, manage, _) {
        return Column(
          children: [
            _buildHeader(),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExportSection(manage),
                    const SizedBox(height: 32),
                    _buildImportSection(context, manage),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: const Row(
        children: [
          Text('Import / Export',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---- Export ----

  Widget _buildExportSection(ManageProvider manage) {
    final hasSelection = manage.importEntityType != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Export',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const InfoTip(
                body:
                    'Select an entity type below, then click Export CSV to download a spreadsheet of all entities of that type. Artists export as names. Genres and Descriptors export with a parent column showing direct hierarchy. Full Database exports all records with flattened relationships.'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Export as:  ',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ImportEntityType?>(
                  value: manage.importEntityType,
                  isDense: true,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  items: const [
                    DropdownMenuItem<ImportEntityType?>(
                        value: null,
                        child: Text('— Select —',
                            style: TextStyle(color: AppColors.textHint))),
                    DropdownMenuItem(
                        value: ImportEntityType.artists,
                        child: Text('Artists')),
                    DropdownMenuItem(
                        value: ImportEntityType.genres,
                        child: Text('Genres')),
                    DropdownMenuItem(
                        value: ImportEntityType.descriptors,
                        child: Text('Descriptors')),
                    DropdownMenuItem(
                        value: ImportEntityType.fullDatabase,
                        child: Text('Full Database')),
                  ],
                  onChanged: (v) {
                    manage.setImportEntityType(v);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor:
                hasSelection ? AppColors.electricBlue : AppColors.textHint,
            side: BorderSide(
                color:
                    hasSelection ? AppColors.electricBlue : AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          icon: Icon(Icons.download,
              size: 16,
              color: hasSelection ? AppColors.electricBlue : AppColors.textHint),
          label: const Text('Export CSV', style: TextStyle(fontSize: 13)),
          onPressed: hasSelection
              ? () async {
                  await manage.executeExport();
                  if (manage.exportCsv != null) {
                    final fileName =
                        _getExportFileName(manage.importEntityType!);
                    _downloadCsv(manage.exportCsv!, fileName);
                    manage.clearExport();
                  }
                }
              : null,
        ),
        const SizedBox(height: 8),
        Text(
            hasSelection
                ? _getExportDescription(manage.importEntityType!)
                : '',
            style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
      ],
    );
  }

  // ---- Import ----

  Widget _buildImportSection(BuildContext context, ManageProvider manage) {
    final hasSelection = manage.importEntityTypeSelection != null;
    final hasFile = manage.importRows != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Import',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const InfoTip(
                body:
                    'Pick a CSV file exported from this app. The file is validated before import — duplicate or already-existing entities are skipped. Broken parent references are ignored. No data is modified until you click Import.'),
          ],
        ),
        const SizedBox(height: 12),
        if (manage.importError != null) ...[
          _buildErrorBanner(manage.importError!),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            const Text('Import as:  ',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ImportEntityType?>(
                    value: manage.importEntityTypeSelection,
                    isDense: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem<ImportEntityType?>(
                          value: null,
                          child: Text('— Select —',
                              style: TextStyle(color: AppColors.textHint))),
                      DropdownMenuItem(
                          value: ImportEntityType.artists,
                          child: Text('Artists')),
                      DropdownMenuItem(
                          value: ImportEntityType.genres,
                          child: Text('Genres')),
                      DropdownMenuItem(
                          value: ImportEntityType.descriptors,
                          child: Text('Descriptors')),
                      DropdownMenuItem(
                          value: ImportEntityType.fullDatabase,
                          child: Text('Full Database')),
                    ],
                    onChanged: (v) {
                      manage.setImportEntityTypeSelection(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      hasSelection ? AppColors.electricBlue : AppColors.textHint,
                  side: BorderSide(
                      color: hasSelection
                          ? AppColors.electricBlue
                          : AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: Icon(Icons.upload_file,
                    size: 16,
                    color: hasSelection
                        ? AppColors.electricBlue
                        : AppColors.textHint),
                label: const Text('Choose CSV File',
                    style: TextStyle(fontSize: 13)),
                onPressed:
                    hasSelection ? () => _pickCsvFile(context, manage) : null,
              ),
              if (manage.importEntityTypeSelection ==
                  ImportEntityType.fullDatabase)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasSelection
                            ? AppColors.electricBlue
                            : AppColors.textHint,
                        side: BorderSide(
                            color: hasSelection
                                ? AppColors.electricBlue
                                : AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: Icon(Icons.text_snippet_outlined,
                          size: 16,
                          color: hasSelection
                              ? AppColors.electricBlue
                              : AppColors.textHint),
                      label: const Text('Download Format of CSV',
                          style: TextStyle(fontSize: 13)),
                      onPressed: hasSelection
                          ? () => _downloadFormatCsv(
                              manage.importEntityTypeSelection!)
                          : null,
                    ),
                    const InfoTip(
                      body:
                          'If you want to write the record data yourself, download '
                          'this format first — it fills in only the header row with '
                          'the correct column names for a full-database CSV. '
                          'Fill in your rows below that row, then use "Choose CSV '
                          'File" to import it.',
                      isMandatory: false,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              hasSelection
                  ? _getImportDescription(manage.importEntityTypeSelection!)
                  : 'Select an entity type above first.',
              style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
          if (hasSelection) ...[
            const SizedBox(height: 4),
            _buildImportDeepDive(context, manage.importEntityTypeSelection!),
          ],
        if (hasFile) ...[
          const SizedBox(height: 12),
          _buildFileNameTag(manage),
        ],
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error),
      ),
      child: Text(message,
          style: const TextStyle(color: AppColors.error, fontSize: 13)),
    );
  }

  Widget _buildFileNameTag(ManageProvider manage) {
    return Row(
      children: [
        const Icon(Icons.description,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(manage.importFileName ?? '',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Text('${manage.importTotal} rows',
            style:
                const TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    );
  }

  // ---- Helpers ----

  String _getExportFileName(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.artists:
        return 'artists.csv';
      case ImportEntityType.genres:
        return 'genres.csv';
      case ImportEntityType.descriptors:
        return 'descriptors.csv';
      case ImportEntityType.fullDatabase:
        return 'full_database.csv';
    }
  }

  String _getExportDescription(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.artists:
        return 'Downloads artists.csv with one column: name.';
      case ImportEntityType.genres:
        return 'Downloads genres.csv with columns: name, parent (direct parent).';
      case ImportEntityType.descriptors:
        return 'Downloads descriptors.csv with columns: name, parent (direct parent).';
      case ImportEntityType.fullDatabase:
        return 'Downloads full_database.csv — all records (Active + Finished) with columns: record_name, artists, genres, descriptors, release_date, type, streaming, URL, comments, status.';
    }
  }

  Widget _buildImportDeepDive(BuildContext context, ImportEntityType type) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding:
            const EdgeInsets.only(left: 8, right: 4, bottom: 8),
        visualDensity: VisualDensity.compact,
        dense: true,
        title: const Text(
          'How it works (click to expand)',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [_buildDeepDiveContent(type)],
      ),
    );
  }

  Widget _buildDeepDiveContent(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.artists:
        return _buildArtistsDeepDive();
      case ImportEntityType.genres:
      case ImportEntityType.descriptors:
        return _buildGenresDescriptorsDeepDive(type);
      case ImportEntityType.fullDatabase:
        return _buildFullDatabaseDeepDive();
    }
  }

  Widget _buildArtistsDeepDive() {
    return _deepDiveSection([
      _deepDiveHeader('Validation'),
      _deepDiveBullet('Header row detection: Row 1 is tested against known '
          'header keywords (name, artist, artists, artist_name, "artist name"). '
          'If matched, it is skipped.'),
      _deepDiveBullet('Row parsing: Only column 1 is read. All extra columns '
          'are silently ignored.'),
      _deepDiveBullet('Each artist name is compared against every existing '
          'artist in the database (case-insensitive, ignoring extra spaces '
          'and punctuation differences).'),
      _deepDiveHeader('Outcome'),
      _deepDiveBullet('Existing artists → silently skipped.'),
      _deepDiveBullet('New artists → inserted into the database.'),
      _deepDiveBullet('Empty rows → silently skipped.'),
    ]);
  }

  Widget _buildGenresDescriptorsDeepDive(ImportEntityType type) {
    final label = type == ImportEntityType.genres ? 'genre' : 'descriptor';
    return _deepDiveSection([
      _deepDiveHeader('Validation'),
      _deepDiveBullet('Header row detection: Row 1 is tested against known '
          'header keywords for name and parent columns.'),
      _deepDiveBullet('Column 1 = name. Column 2 = parent (optional).'),
      _deepDiveBullet('Each name is compared against every existing $label '
          'in the database (case-insensitive, ignoring extra spaces '
          'and punctuation differences).'),
      _deepDiveHeader('Parent Handling'),
      _deepDiveBullet('Parent column present but blank → root entry (no warning).'),
      _deepDiveBullet('Parent column present with value → looked up in the '
          'database. If not found → rectification dialog '
          '(Skip Tuple / Cancel Import).'),
      _deepDiveBullet('Parent column absent entirely → all entries inserted as '
          'root. You will see a warning if parent column is missing.'),
      _deepDiveHeader('Outcome'),
      _deepDiveBullet('Existing ${label}s → silently skipped.'),
      _deepDiveBullet('New ${label}s → inserted, parent-child link created '
          'if parent was provided and found.'),
    ]);
  }

  Widget _buildFullDatabaseDeepDive() {
    return _deepDiveSection([
      _deepDiveHeader('CSV Format'),
      _deepDiveBullet('Exactly 10 columns allowed: record_name, artists, '
          'genres, descriptors, release_date, type, streaming, URL, comments, '
          'status.'),
      _deepDiveBullet('Column order does not matter as long as column has '
          'appropriate heading.'),
      _deepDiveBullet('Column 11 or more → silently skipped.'),
      _deepDiveBullet('date_added column present → hard stop. Options: '
          'Proceed (date = today for all records) or Cancel Import. '
          'User not allowed to provide custom date_added values for '
          'individual tuples — handled by the app only.'),
      _deepDiveHeader('Record Name'),
      _deepDiveBullet('Duplicates within the file are rejected (first occurrence '
          'wins, rest go to skip queue). Detected via record_name.'),
      _deepDiveBullet('Existing records in the database (by exact name) → '
          'silently skipped.'),
      _deepDiveHeader('Artists'),
      _deepDiveBullet('Each artist name is looked up in the existing database.'),
      _deepDiveBullet('Match found → linked to the record. Not found → Flagged.'),
      _deepDiveBullet('Pop up dialog lets you select the correct artist '
          'from a list of all existing artists.'),
      _deepDiveBullet('Options: Proceed (Blank Cell) — remove the bad '
          'artist and keep the rest; Auto-Fix — same, one click; Rectify — '
          'pick a replacement from all existing artists; Skip Tuple (skip '
          'this record); or Cancel Import (abort everything).'),
      _deepDiveHeader('Genres & Descriptors'),
      _deepDiveBullet('Each name is looked up in the existing database.'),
      _deepDiveBullet('Match found → linked to the record. Not found → Flagged; '
          'provided options: Proceed (Blank Cell), Auto-Fix, Cancel Import.'),
      _deepDiveBullet('If ALL genres or descriptors are removed from a record, '
          'the record is still imported with empty genre/descriptor lists.'),
      _deepDiveHeader('Streaming'),
      _deepDiveBullet('Each streaming value is matched against accepted '
          'services: Spotify, Youtube, SoundCloud, Bandcamp, SoulSeekQT.'),
      _deepDiveBullet('Close variations (e.g. "soulseek", "ssqt", "sound cloud") '
          'are accepted and automatically corrected to the official name.'),
      _deepDiveBullet('Unrecognized streaming → Flagged; provided options: '
          'Proceed (blank the cells), Auto-fix (remove unknowns), '
          'Skip Tuple, or Cancel Import.'),
      _deepDiveBullet('If the URL column has more entries than the streaming '
          'column, the extra URLs are silently ignored — no warning, noted '
          'only in the summary under "Streaming / URL — extra URLs ignored".'),
      _deepDiveHeader('Separators'),
      _deepDiveBullet('Valid separators within cells: comma (","), comma + space '
          '(", "), pipe ("|"), pipe + space ("| ").'),
      _deepDiveBullet('Fields that require appropriate separations: genres, '
          'descriptors, streaming, URL.'),
      _deepDiveHeader('Date Formats'),
      _deepDiveBullet('Accepted: YYYY, YYYY-MM, YYYY-MM-DD, DD-MM-YYYY, '
          'MM-YYYY, YYYY/MM, YYYY/MM/DD, DD/MM/YYYY, MM/YYYY.'),
      _deepDiveBullet('Unrecognized format → Flagged; provided options: '
          'Proceed (blank the cells), Cancel Import.'),
      _deepDiveHeader('Status'),
      _deepDiveBullet('"Finished" / False / false / F / f / 0 → Finished.'),
      _deepDiveBullet('"Active" / True / true / T / t / 1 → Active.'),
      _deepDiveBullet('Empty or unrecognized → defaults to Active (auto-applied, '
          'counted in summary).'),
      _deepDiveHeader('Rectification Order'),
      _deepDiveBullet('1. Record Type Invalid dialog.'),
      _deepDiveBullet('2. Artist mismatch dialog.'),
      _deepDiveBullet('3. Streaming warnings.'),
      _deepDiveBullet('4. Date format warnings.'),
      _deepDiveBullet('5. Genre mismatch warnings.'),
      _deepDiveBullet('6. Descriptor mismatch warnings.'),
    ]);
  }

  // ── Deep-dive helper widgets ──────────────────────────────────────────

  Widget _deepDiveSection(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _deepDiveHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _deepDiveBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getImportDescription(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.artists:
        return 'Format: CSV with one column — artist name.\n'
            '• Row 1 can be a header (accepted: name, artist, artists, artist_name, "artist name") — auto-detected and skipped.\n'
            '• Only column 1 is read. Extra columns are silently ignored.\n'
            '• Existing artists (matched case-insensitively) are skipped silently.\n'
            '• Empty rows are skipped silently.';
      case ImportEntityType.genres:
        return 'Format: CSV with 2 columns — genre name, and optionally parent genre.\n'
            '• First column = genre name. Second column = parent genre.\n'
            '• Row 1 header auto-detection (accepted: name, genre, genres, genre_name, "genre name", genrename, parent, parent_genre, "parent genre", parentgenre).\n'
            '• If only 1 column detected: all genres inserted as root. You will be warned if this column is missing.\n'
            '• If Parent cell blank = root entry (no warning).\n'
            '• Existing genres (matched case-insensitively) are skipped silently.';
      case ImportEntityType.descriptors:
        return 'Format: CSV with 1-2 columns — descriptor name, and optionally parent descriptor.\n'
            '• First column = descriptor name. Second column = parent descriptor.\n'
            '• Row 1 header auto-detection (accepted: name, descriptor, descriptors, descriptor_name, "descriptor name", descriptorname, parent, parent_descriptor, "parent descriptor", parentdescriptor).\n'
            '• If only 1 column detected: all descriptors inserted as root. You will be warned if this column is missing.\n'
            '• If Parent cell blank = root entry (no warning).\n'
            '• Existing descriptors (matched case-insensitively) are skipped silently.';
      case ImportEntityType.fullDatabase:
        return 'Import a full_database.csv exported from this app. Records with all '
            'relationships (artists, genres, descriptors, streaming) are imported.\n'
            '• Column headings are mandatory (case-insensitive).\n'
            '• Expected columns: record_name, artists, genres, descriptors, release_date, '
            'type, streaming, URL, comments, status.\n'
            '• Mandatory Columns: record_name, artists.\n'
            '• Artists, genres, and descriptors must already exist in the database. '
            'New entities are NOT created — unrecognized names are flagged.\n'
            '• Existing records (by name) are silently skipped.\n'
            '• Separator rules: comma ("," or ", ") and pipe ("|" or "| ") are valid.\n'
            '• Accepted status values: Finished/False/F/0 → Finished, Active/True/T/1 → Active.\n'
            '• Streaming values are matched against accepted services (Spotify, Youtube, etc.).\n'
            '• Accepted date formats: YYYY, YYYY-MM, YYYY-MM-DD, DD-MM-YYYY, MM-YYYY, '
            'YYYY/MM, YYYY/MM/DD, DD/MM/YYYY, MM/YYYY.';
    }
  }
}
