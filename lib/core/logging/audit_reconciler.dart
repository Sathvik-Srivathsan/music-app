import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/logging/record_audit_logger.dart';
import 'package:music_collection/core/network/supabase_client.dart';
import 'package:music_collection/features/search/data/repositories/search_repository.dart';
import 'package:music_collection/shared/models/record_details.dart';

/// Self-healing gap repair for the client-side record audit log.
///
/// The app writes one full-tuple audit row per record commit. If the client
/// crashes between the data write and the log write (or a write bypassed the
/// app entirely), that record silently ends up with no log entry. The
/// reconciler finds such gaps and repairs them by rebuilding the full tuple
/// straight from the DB and writing the missing entry stamped `reconciled`.
///
/// Stage 1 coverage: INSERT gaps (a record that exists with no logged insert).
/// This is reliably detectable without extra markers. UPDATE/DELETE gap
/// repair needs the Stage-2 write-marker/outbox to know a record was touched,
/// and is added there.
class AuditReconciler {
  /// Fetches every full tuple (row + joined entities). Defaults to
  /// [SearchRepository.fetchAllRecordDetails].
  final Future<FetchResult> Function() fetchRecords;

  /// Returns the set of record_ids that already have an `insert` audit row.
  /// Defaults to paging the audit_log for records-insert entries.
  final Future<Set<int>> Function() fetchLoggedInsertRecordIds;

  /// Writes the repaired audit row (stamped `reconciled: true`). Defaults to
  /// [RecordAuditLogger].
  final Future<void> Function(RecordDetails details, String originTab,
      {String action}) logRecord;

  /// Which origin_tab to stamp on repaired entries.
  final String originTab;

  /// Only records created on/after this date are reconciled. Legacy records
  /// (e.g. imported via CSV, which carry their own aggregate import_records
  /// log) are left alone so the audit log is not flooded with backfilled
  /// inserts. Defaults to the app/collection roll-out date (today).
  final DateTime reconcileSince;

  AuditReconciler({
    SearchRepository? repo,
    Future<FetchResult> Function()? fetchRecords,
    Future<Set<int>> Function()? fetchLoggedInsertRecordIds,
    Future<void> Function(RecordDetails, String, {String action})? logRecord,
    this.originTab = 'reconciler',
    DateTime? reconcileSince,
  })  : assert(fetchRecords == null || repo == null,
            'Provide fetchRecords OR repo, not both'),
        reconcileSince = reconcileSince ?? DateTime.now(),
        fetchRecords = fetchRecords ??
            (repo ?? SearchRepository()).fetchAllRecordDetails,
        fetchLoggedInsertRecordIds = fetchLoggedInsertRecordIds ??
            _defaultFetchLoggedInsertRecordIds,
        logRecord = logRecord ??
            ((details, tab, {String action = 'insert'}) =>
                RecordAuditLogger.logRecordAction(
                  action: action,
                  details: details,
                  originTab: tab,
                  extraDetails: const {'reconciled': true},
                ));

  /// Scans for records that exist but have no logged insert, and repairs each
  /// one. Returns the record_ids that were repaired. Failures fetch- or
  /// log-side are absorbed so a partial hiccup never aborts the whole pass.
  Future<List<int>> reconcile() async {
    final repaired = <int>[];
    try {
      final result = await fetchRecords();
      final logged = await fetchLoggedInsertRecordIds();
      for (final details in result.rows) {
        final id = details.record.recordId;
        if (id == null) continue;
        if (logged.contains(id)) continue;
        if (!_eligibleByDate(details)) continue;
        try {
          await logRecord(details, originTab, action: 'insert');
          repaired.add(id);
        } catch (_) {
          // keep going; the next pass retries this one
        }
      }
    } catch (_) {
      // fetch failed; nothing repaired this pass
    }
    return repaired;
  }

  /// True only when the record was created on/after [reconcileSince]. Records
  /// with an unparseable or earlier date_added are treated as legacy and left
  /// alone.
  bool _eligibleByDate(RecordDetails details) {
    final raw = details.record.dateAdded;
    if (raw == null) return false;
    final parsed = _parseDmy(raw);
    if (parsed == null) return false;
    return !parsed.isBefore(reconcileSinceOnlyDate);
  }

  /// Date-only (midnight) form of [reconcileSince] for inclusive comparison.
  DateTime get reconcileSinceOnlyDate =>
      DateTime(reconcileSince.year, reconcileSince.month, reconcileSince.day);

  /// Parses `DD/MM/YYYY` (the stored display format) into a local date, or
  /// null when the string doesn't match.
  static DateTime? _parseDmy(String raw) {
    final parts = raw.trim().split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  /// Paged read of every audit_log row for a records insert, returning the set
  /// of record_ids already logged.
  static Future<Set<int>> _defaultFetchLoggedInsertRecordIds() async {
    final ids = <int>{};
    final pageSize = AppConstants.defaultPageSize;
    var from = 0;
    while (true) {
      final page = await SupabaseService.from(AppConstants.tableAuditLog)
          .select('record_id')
          .eq('table_name', AppConstants.tableRecords)
          .eq('action', 'insert')
          .range(from, from + pageSize - 1);
      final rows = (page as List).cast<Map<String, dynamic>>();
      for (final r in rows) {
        final rid = r['record_id'];
        if (rid is int) ids.add(rid);
      }
      if (rows.length < pageSize) break;
      from += pageSize;
    }
    return ids;
  }
}
