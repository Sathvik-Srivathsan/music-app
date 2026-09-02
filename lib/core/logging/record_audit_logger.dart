import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/network/supabase_client.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/utils/record_tuple_log.dart';

/// Client-side record audit logging.
///
/// The record-level trigger logs per *row*, so it can never produce a single
/// entry for a whole record commit (a genre edit touches many link rows) and
/// never has the full before/after tuple. Only the app knows the full
/// [RecordDetails] at commit time, so the app writes these entries itself:
/// one audit_log row per commit with the complete tuple.
///
/// Reliability: the write is retried a few times on transient failure, and it
/// is intentionally fire-and-forget / non-blocking (log failures never break
/// the actual data write). A separate reconciler pass fills any gap that
/// survives a crash or a forgotten call site.
class RecordAuditLogger {
  RecordAuditLogger._();

  static const int _maxAttempts = 3;

  /// Writes one audit row for a whole-record operation. Call AFTER the data
  /// write succeeds (so record_id and any server-assigned values are known).
  ///
  /// The returned future resolves after the log row is confirmed inserted (or
  /// all retries are exhausted). Callers should `unawaited(...)` this so the
  /// data write already returned; any failure is absorbed here.
  static Future<void> logRecordAction({
    required String action,
    required RecordDetails details,
    required String originTab,
    Map<String, dynamic>? extraDetails,
    String? opId,
  }) async {
    final recordId = details.record.recordId;

    final baseDetails = switch (action) {
      'insert' => RecordTupleLog.insertDetails(details),
      'update' => throw ArgumentError(
          'Use logRecordUpdate for update actions (needs before+after).'),
      'delete' => RecordTupleLog.deleteDetails(details),
      _ => throw ArgumentError('Unsupported record action: $action'),
    };

    final composedDetails = <String, dynamic>{
      ...baseDetails,
      if (extraDetails != null) ...extraDetails,
      if (opId != null) '_op_id': opId,
    };

    await _insert(action, recordId, originTab, composedDetails);
  }

  /// Logs a record update with both full tuples so the viewer can show "what
  /// changed" plus the whole before/after state.
  static Future<void> logRecordUpdate({
    required RecordDetails before,
    required RecordDetails after,
    required String originTab,
    String? opId,
  }) async {
    final details = RecordTupleLog.updateDetails(before, after);
    if (opId != null) details['_op_id'] = opId;
    await _insert('update', after.record.recordId, originTab, details);
  }

  static Future<void> _insert(
    String action,
    int? recordId,
    String originTab,
    Map<String, dynamic> details,
  ) async {
    var attempt = 0;
    while (attempt < _maxAttempts) {
      attempt++;
      try {
        await SupabaseService.fromWithContext(AppConstants.tableAuditLog, originTab)
            .insert({
              'action': action,
              'table_name': AppConstants.tableRecords,
              'record_id': recordId,
              'details': details,
              'device': SupabaseService.device,
            });
        return; // confirmed
      } catch (_) {
        if (attempt >= _maxAttempts) return; // give up silently
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }
}
