import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/statistics/domain/audit_log_sentence.dart';
import 'package:music_collection/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:music_collection/shared/models/audit_log.dart';
import 'package:music_collection/shared/widgets/empty_state_widget.dart';
import 'package:music_collection/shared/widgets/error_widget.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';
import 'package:music_collection/shared/widgets/loading_indicator.dart';

/// The read-only audit-log viewer under Statistics > Log.
///
/// Latches onto [StatisticsProvider]'s log state: filters (action, table,
/// free-text), a zebra-striped list, server-side pagination, and a refresh
/// action. Rows are immutable; tapping one opens a Close-only detail dialog
/// that never shows ids.
class LogViewer extends StatelessWidget {
  const LogViewer({super.key});

  static const List<String> _actions = [
    'insert',
    'update',
    'delete',
    'import_artists',
    'import_genres',
    'import_descriptors',
    'import_records',
    'app_boot',
  ];

  static const List<String> _tables = [
    'records',
    'artists',
    'genres',
    'descriptors',
    'record_artists',
    'record_genres',
    'record_descriptors',
    'record_streaming',
    'genre_hierarchy',
    'descriptor_hierarchy',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, stats, _) {
        return Column(
          children: [
            _FilterBar(stats: stats),
            _TableToolbar(stats: stats),
            Expanded(
              child: _content(stats),
            ),
          ],
        );
      },
    );
  }

  Widget _content(StatisticsProvider stats) {
    if (stats.logLoading && stats.logs.isEmpty) {
      return const AppLoadingIndicator(message: 'Loading audit log...');
    }
    if (stats.logError != null && stats.logs.isEmpty) {
      return AppErrorWidget(
        message: stats.logError!,
        onRetry: () => stats.loadLogs(),
      );
    }
    if (stats.logs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        message: 'No audit log entries match these filters.',
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _LogTable(logs: stats.logs),
    );
  }
}

/// Column descriptor for the journal table.
class _Col {
  final String label;
  final int flex;
  const _Col(this.label, this.flex);
}

class _LogTable extends StatefulWidget {
  final List<AuditLog> logs;
  const _LogTable({required this.logs});

  static const double _headerH = 36;
  static const double _rowHeight = 40;

  @override
  State<_LogTable> createState() => _LogTableState();
}

class _LogTableState extends State<_LogTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const List<_Col> _cols = [
    _Col('Time', 4),
    _Col('Action', 3),
    _Col('Table', 4),
    _Col('Origin', 3),
    _Col('Device', 3),
    _Col('Details', 8),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: _LogTable._headerH,
            child: Row(
              children: [
                for (final col in _cols) _headerCell(col),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              interactive: true,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.logs.length,
                itemBuilder: (context, index) {
                  final log = widget.logs[index];
                  return _bodyRow(context, log, index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(_Col col) {
    return Expanded(
      flex: col.flex,
      child: Container(
        height: _LogTable._headerH,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          col.label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _rowBg(int i) =>
      i.isEven ? AppColors.background : AppColors.card.withOpacity(0.5);

  Widget _bodyRow(BuildContext context, AuditLog log, int i) {
    final summary = AuditLogSentence.build(log);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showLogDetailDialog(context, log),
        child: SizedBox(
          height: _LogTable._rowHeight,
          child: Row(
            children: [
              _cell(log.formattedTime, 4, i),
              _cell(_actionLabel(log.action), 3, i),
              _cell(log.tableName.replaceAll('_', ' '), 4, i),
              _cell(log.originTab ?? '', 3, i),
              _cell(log.device ?? '', 3, i),
              _denseCell(summary, 8, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, int flex, int i) {
    return Expanded(
      flex: flex,
      child: Container(
        height: _LogTable._rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _rowBg(i),
          border: const Border(
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
      ),
    );
  }

  Widget _denseCell(String text, int flex, int i) {
    return Expanded(
      flex: flex,
      child: Container(
        height: _LogTable._rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _rowBg(i),
          border: const Border(
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: text,
          showDuration: const Duration(seconds: 3),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

String _actionLabel(String action) {
  switch (action) {
    case 'insert':
      return 'Insert';
    case 'update':
      return 'Update';
    case 'delete':
      return 'Delete';
    case 'import_artists':
    case 'import_genres':
    case 'import_descriptors':
    case 'import_records':
      return 'Import';
    case 'app_boot':
      return 'Boot';
    default:
      return action;
  }
}

class _FilterBar extends StatelessWidget {
  final StatisticsProvider stats;
  const _FilterBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hint(
            'Filter the log:\n'
            '  • Action — pick a kind of change (insert, update, delete, import, boot).\n'
            '  • Table — pick which table was changed.\n'
            '  • Search box — free-text match against the summary details.\n'
            'Leave a filter on "All" or the search empty to see everything. '
            'Refresh reloads the current page; use the arrows on the top-right '
            'of the table to page through older entries.',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Dropdown(
                  label: 'Action',
                  value: stats.logActionFilter,
                  options: LogViewer._actions,
                  onChanged: stats.setLogActionFilter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dropdown(
                  label: 'Table',
                  value: stats.logTableFilter,
                  options: LogViewer._tables,
                  onChanged: stats.setLogTableFilter,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh audit log',
                onPressed: stats.logLoading ? null : stats.refreshLogs,
                icon: const Icon(Icons.refresh, color: AppColors.electricBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('log-search-field'),
            decoration: const InputDecoration(
              hintText: 'Search log details...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              isDense: true,
            ),
            onChanged: stats.setLogSearch,
          ),
        ],
      ),
    );
  }

  Widget _hint(String text) {
    return InfoTip(body: text, isMandatory: false);
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return DropdownButtonFormField<String>(
      key: ValueKey(label),
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: [
        DropdownMenuItem<String>(value: null, child: const Text('All')),
        for (final o in options)
          DropdownMenuItem<String>(value: o, child: Text(o)),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }
}

class _TableToolbar extends StatelessWidget {
  final StatisticsProvider stats;
  const _TableToolbar({required this.stats});

  static const String _columnHelp =
      'Columns (tap a row for full before/after values):\n'
      '  • Time — when the change was recorded (Indian Standard Time, IST).\n'
      '  • Action — insert, update, delete, or a higher-level summary such as an import or app boot.\n'
      '  • Table — which database table the change touched (records, artists, genres, descriptors, links, hierarchy).\n'
      '  • Origin — which screen made the change: insert, search, db, manage, or boot.\n'
      '  • Device — whether the change came from the web or a mobile device.\n'
      '  • Details — a short human-readable summary. Click a row for the full before/after fields.';

  @override
  Widget build(BuildContext context) {
    final hasPages =
        stats.logs.isNotEmpty || stats.logPage > 0 || stats.logHasMore;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          InfoTip(body: _columnHelp, isMandatory: false),
          const Spacer(),
          if (hasPages) _pagesControl(context),
        ],
      ),
    );
  }

  Widget _pagesControl(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'First page',
          onPressed: stats.logPage == 0 || stats.logLoading
              ? null
              : stats.goFirstLogPage,
          icon: const Icon(Icons.first_page, size: 22),
          color: AppColors.electricBlue,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Previous page',
          onPressed: stats.logPage == 0 || stats.logLoading
              ? null
              : stats.prevLogPage,
          icon: const Icon(Icons.chevron_left, size: 22),
          color: AppColors.electricBlue,
        ),
        Text(
          'Page ${stats.logPage + 1}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Next page',
          onPressed: !stats.logHasMore || stats.logLoading
              ? null
              : stats.nextLogPage,
          icon: const Icon(Icons.chevron_right, size: 22),
          color: AppColors.electricBlue,
        ),
      ],
    );
  }
}

/// Accent style per action type (also drives the detail header).
(IconData, Color) _accent(AuditLog log) {
  switch (log.action) {
    case 'insert':
      return (Icons.add_circle_outline, AppColors.success);
    case 'update':
      return (Icons.edit_outlined, AppColors.info);
    case 'delete':
      return (Icons.delete_outline, AppColors.coralRed);
    case 'import_records':
    case 'import_artists':
    case 'import_genres':
    case 'import_descriptors':
      return (Icons.file_download_outlined, AppColors.vividOrange);
    case 'app_boot':
      return (Icons.power_settings_new, AppColors.lavenderPurple);
    default:
      return (Icons.receipt_long_outlined, AppColors.textSecondary);
  }
}

/// Opens the read-only detail dialog. The only control is Close, and no id
/// is ever shown (only admins see ids, by querying the DB directly).
Future<void> showLogDetailDialog(BuildContext context, AuditLog log) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _LogDetailBody(log: log),
      ),
    ),
  );
}

class _LogDetailBody extends StatelessWidget {
  final AuditLog log;
  const _LogDetailBody({required this.log});

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = _accent(log);
    final sections = _tupleSections(log);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      log.formattedTime,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 24),
          Text(
            AuditLogSentence.build(log),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (sections.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final s in sections) ...[
              _TupleSection(label: s.label, rows: s.rows),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  String _title() {
    final label = switch (log.action) {
      'insert' => 'Added',
      'update' => 'Updated',
      'delete' => 'Deleted',
      'import_artists' => 'Import',
      'import_genres' => 'Import',
      'import_descriptors' => 'Import',
      'import_records' => 'Import',
      'app_boot' => 'App boot',
      _ => log.action,
    };
    return '$label  ·  ${log.tableName.replaceAll('_', ' ')}';
  }
}

/// A titled block of name → value rows shown in the detail dialog.
class _TupleSection extends StatelessWidget {
  final String label;
  final List<MapEntry<String, String>> rows;
  const _TupleSection({required this.label, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        _MetaTable(rows: rows),
      ],
    );
  }
}

const Map<String, String> _logFriendlyNames = {
  'record_name': 'Name',
  'record_type': 'Type',
  'release_date': 'Release date',
  'date_added': 'Date added',
  'comments': 'Comments',
  'status': 'Status',
  'artist_name': 'Artist',
  'genre_name': 'Genre',
  'descriptor_name': 'Descriptor',
  'service_name': 'Service',
  'service_url': 'URL',
  'count': 'Count',
  'records': 'Records',
  'hierarchy_edges': 'Hierarchy edges',
  'artist_links': 'Artist links',
  'genre_links': 'Genre links',
  'descriptor_links': 'Descriptor links',
  'streaming_links': 'Streaming links',
  'device': 'Device',
  'old_name': 'Old name',
  'new_name': 'New name',
};

/// Maps a raw tuple map into display rows: friendly labels, ids hidden,
/// empty/null values dropped.
List<MapEntry<String, String>> _tupleRows(Map<String, dynamic> map) {
  final out = <MapEntry<String, String>>[];
  map.forEach((k, v) {
    if (k.endsWith('_id') || k == 'record_id') return; // hide ids
    if (v == null || v == '') return;
    out.add(MapEntry(_logFriendlyNames[k] ?? k, v.toString()));
  });
  return out;
}

/// Builds the detail sections for a log row from its `details` map:
///  * records update → "What changed", then the full After and Before tuples
///  * insert/delete → the full Added/Deleted tuple
///  * anything else → the raw key/value details
List<_TupleSection> _tupleSections(AuditLog log) {
  final d = log.details ?? const <String, dynamic>{};
  final sections = <_TupleSection>[];

  final before = d['before'];
  final after = d['after'];
  if (before is Map && after is Map) {
    final changed = <MapEntry<String, String>>[];
    final keys = <String>{...before.keys, ...after.keys};
    for (final k in keys) {
      if (k.endsWith('_id') || k == 'record_id') continue;
      final b = before[k];
      final a = after[k];
      if (b == a) continue;
      changed.add(MapEntry(
        _logFriendlyNames[k] ?? k,
        '${b ?? '—'}  →  ${a ?? '—'}',
      ));
    }
    if (changed.isNotEmpty) {
      sections.add(_TupleSection(label: 'What changed', rows: changed));
    }
    sections.add(_TupleSection(
      label: 'New value (full tuple)',
      rows: _tupleRows(after as Map<String, dynamic>),
    ));
    sections.add(_TupleSection(
      label: 'Previous value (full tuple)',
      rows: _tupleRows(before as Map<String, dynamic>),
    ));
  } else if (d['inserted'] is Map) {
    sections.add(_TupleSection(
      label: 'Added (full tuple)',
      rows: _tupleRows(d['inserted'] as Map<String, dynamic>),
    ));
  } else if (d['deleted'] is Map) {
    sections.add(_TupleSection(
      label: 'Deleted (full tuple)',
      rows: _tupleRows(d['deleted'] as Map<String, dynamic>),
    ));
  } else if (d.isNotEmpty) {
    sections.add(_TupleSection(label: 'Details', rows: _tupleRows(d)));
  }
  return sections;
}

class _MetaTable extends StatelessWidget {
  final List<MapEntry<String, String>> rows;
  const _MetaTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            color: i.isOdd ? AppColors.card : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    rows[i].key,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
