import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/network/supabase_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage seam so tests can use an in-memory store instead of the real
/// (channel-backed) [SharedPreferences]. Loads the raw JSON blob, or null.
typedef OutboxLoad = Future<String?> Function();

/// Storage seam; saves the raw JSON blob.
typedef OutboxSave = Future<void> Function(String json);

/// Returns the set of `_op_id` values already present in the audit_log (so a
/// flush never double-writes an entry whose log actually landed before the
/// local remove happened).
typedef LoggedOpIdsFetcher = Future<Set<String>> Function();

/// Writes a single audit-log row (stamped with its `_op_id` highlighted via
/// [opId]). Defaults to the real Supabase-backed insert with retry; injectable
/// for tests.
typedef OutboxWriteEntry = Future<void> Function({
  required String action,
  required int? recordId,
  required String originTab,
  required Map<String, dynamic> details,
  required String opId,
});

/// A single pending audit-log write that must survive an app crash.
///
/// Flow (per record commit): the caller [enqueue]s the intended entry with the
/// full tuple BEFORE doing the DB write, performs the DB write, then confirms —
/// normally the entry is written to the audit_log and removed from the outbox
/// in one go. If the process dies anywhere in between, the entry stays queued
/// and [flush] re-issues it on the next launch. Nothing is dependency-heavy:
/// entries are stored as JSON in [SharedPreferences] keyed by a generated
/// `_op_id`.
class AuditOutbox {
  static const String _prefsKey = 'audit_outbox_v1';

  /// Shared app-wide instance used by the record commit sites and app startup.
  static final AuditOutbox shared = AuditOutbox();

  final OutboxLoad _load;
  final OutboxSave _save;
  final LoggedOpIdsFetcher _loggedOpIds;
  final OutboxWriteEntry _writeEntry;
  final Random _random;

  /// Lazily bound real [SharedPreferences] backend.
  AuditOutbox({
    OutboxLoad? load,
    OutboxSave? save,
    LoggedOpIdsFetcher? loggedOpIds,
    OutboxWriteEntry? writeEntry,
  })  : _load = load ?? _defaultLoad,
        _save = save ?? _defaultSave,
        _loggedOpIds = loggedOpIds ?? _defaultLoggedOpIds,
        _writeEntry = writeEntry ?? _defaultWriteEntry,
        _random = Random();

  /// Number of currently-pending entries.
  int pendingCount = 0;

  static Future<String?> _defaultLoad() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  static Future<void> _defaultSave(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json);
  }

  /// Reads the audit_log and returns every `_op_id` stamped on a client entry.
  static Future<Set<String>> _defaultLoggedOpIds() async {
    final ids = <String>{};
    const pageSize = AppConstants.defaultPageSize;
    var from = 0;
    while (true) {
      final page = await SupabaseService.from(AppConstants.tableAuditLog)
          .select('details')
          .not('details', 'is', null)
          .range(from, from + pageSize - 1);
      final rows = (page as List).cast<Map<String, dynamic>>();
      for (final r in rows) {
        final details = r['details'];
        if (details is Map) {
          final opId = details['_op_id'];
          if (opId is String && opId.isNotEmpty) ids.add(opId);
        }
      }
      if (rows.length < pageSize) break;
      from += pageSize;
    }
    return ids;
  }

  /// Queues a pending audit-log write. [details] should be the already-composed
  /// full-tuple map (`insertDetails`/`updateDetails`/`deleteDetails`); it is
  /// stamped with a generated `_op_id` when actually written.
  ///
  /// Returns the generated `op_id` so the caller can stamp the same id onto the
  /// immediately-following audit write; [flush] later treats entries whose
  /// `_op_id` already landed as confirmed and prunes them (idempotent).
  ///
  /// Never throws on storage failure: a failed enqueue just means the entry is
  /// not durably queued (the app should still proceed with the data write).
  Future<String> enqueue({
    required String action,
    required Map<String, dynamic> details,
    required int? recordId,
    required String originTab,
  }) async {
    final opId = _generateOpId();
    final entry = {
      'op_id': opId,
      'action': action,
      'record_id': recordId,
      'origin_tab': originTab,
      'details': details,
      'queued_at': DateTime.now().toIso8601String(),
    };
    try {
      final entries = await readPending();
      entries.add(entry);
      pendingCount = entries.length;
      await _writeAll(entries);
    } catch (_) {
      // Best-effort queue; never block the data write.
    }
    return opId;
  }

  /// Re-issues every pending entry. Entries whose `_op_id` already landed in
  /// the audit_log are treated as confirmed and just removed locally. Returns
  /// the number of entries that were newly written. Failures stay queued.
  Future<int> flush() async {
    final entries = await readPending();
    if (entries.isEmpty) return 0;

    Set<String> logged;
    try {
      logged = await _loggedOpIds();
    } catch (_) {
      logged = <String>{};
    }

    var written = 0;
    final remaining = <Map<String, dynamic>>[];
    for (final e in entries) {
      final opId = e['op_id'] as String;
      final action = e['action'] as String;
      final recordId = e['record_id'] as int?;
      final originTab = e['origin_tab'] as String;
      final rawDetails = e['details'];
      final details = (rawDetails is Map) ? Map<String, dynamic>.from(rawDetails) : <String, dynamic>{};

      if (logged.contains(opId)) {
        continue; // already landed; treat as confirmed
      }

      details['_op_id'] = opId;
      try {
        await _writeEntry(
          action: action,
          recordId: recordId,
          originTab: originTab,
          details: details,
          opId: opId,
        );
        written++;
      } catch (_) {
        remaining.add(e); // keep for next flush
      }
    }

    pendingCount = remaining.length;
    try {
      await _writeAll(remaining);
    } catch (_) {
      // If the prune failed we may re-write duplicates next time; the
      // _op_id dedupe above prevents actual duplicate rows.
    }
    return written;
  }

  static Future<void> _defaultWriteEntry({
    required String action,
    required int? recordId,
    required String originTab,
    required Map<String, dynamic> details,
    required String opId,
  }) async {
    const maxAttempts = 3;
    var attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        await SupabaseService.fromWithContext(AppConstants.tableAuditLog, originTab).insert({
          'action': action,
          'table_name': AppConstants.tableRecords,
          'record_id': recordId,
          'details': details,
          'device': SupabaseService.device,
        });
        return;
      } catch (_) {
        if (attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  // Small in-memory cache so read/write don't hammer prefs per call.
  String? _cachedRaw;

  Future<List<Map<String, dynamic>>> readPending() async {
    _cachedRaw = await _load();
    return _decode(_cachedRaw);
  }

  static List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAll(List<Map<String, dynamic>> entries) async {
    final json = jsonEncode(entries);
    _cachedRaw = json;
    await _save(json);
  }

  String _generateOpId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rnd = List.generate(8, (_) => _random.nextInt(16).toRadixString(16)).join();
    return 'op_$ts$rnd';
  }
}
