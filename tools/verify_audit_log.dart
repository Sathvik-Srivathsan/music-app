// verify_audit_log.dart
//
// HARMLESS by default: performs NO writes. It calls the read-only
// fn_verify_audit_triggers() function (added by the audit-log migration) over
// the Supabase REST API and reports, per data table, whether the fn_audit_log
// trigger is attached and how many audit rows already exist for that table.
//
// Record+link tables are now client-logged (the trigger skips them since the
// Stage-1 rework), so this also runs a read-only GAP check: every record in
// `records` must have a corresponding `insert` audit row. Any gap is one the
// app's AuditReconciler would repair (stamped `reconciled: true`).
//
// Usage:
//   dart run tools/verify_audit_log.dart            # harmless trigger + gap check
//   dart run tools/verify_audit_log.dart --burn     # ALSO live smoke test
//
// The --burn flag runs a true end-to-end probe: it INSERTs a temporary artist
// via the REST API (REST over rpc would bypass triggers, so --burn exercises
// triggers through raw table INSERT), checks that a matching audit row was
// produced, then tries to DELETE that artist. NOTE: --burn adds +1 audit row
// (artist create) and +1 (artist delete) that you should clean up before you
// flip on RLS. Default (no flag) is purely read-only.

import 'dart:convert';
import 'dart:io';

// Credentials come from the environment only (no literals in the repo). Set
// SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in your shell/.env before running:
//   dart run tools/verify_audit_log.dart
final String url = Platform.environment['SUPABASE_URL'] ?? '';
final String key = Platform.environment['SUPABASE_PUBLISHABLE_KEY'] ?? '';

void _requireEnv() {
  final missing = <String>[
    if (url.isEmpty) 'SUPABASE_URL',
    if (key.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('ERROR: missing required env var(s): ${missing.join(', ')}');
    stderr.writeln('Set them in your environment/.env before running, e.g.:');
    stderr.writeln('  set SUPABASE_URL=https://<ref>.supabase.co');
    stderr.writeln('  set SUPABASE_PUBLISHABLE_KEY=<publishable-key>');
    stderr.writeln('Then re-run this tool.');
    exit(1);
  }
}

Future<dynamic> _request(String method, String path,
    {String? body, String? contentType}) async {
  final uri = Uri.parse('$url$path');
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, uri);
    req.headers.set('apikey', key);
    req.headers.set('Authorization', 'Bearer $key');
    if (contentType != null) req.headers.set('Content-Type', contentType);
    if (body != null) req.write(body);
    final resp = await req.close();
    final raw = await resp.transform(utf8.decoder).join();
    final code = resp.statusCode;
    final json = raw.isEmpty ? null : jsonDecode(raw);
    return {'code': code, 'body': json, 'raw': raw};
  } finally {
    client.close(force: true);
  }
}

Future<void> verifyTriggers() async {
  print('=== AUDIT LOG TRIGGER EXISTENCE CHECK (read-only) ===');
  final r = await _request('POST', '/rest/v1/rpc/fn_verify_audit_triggers',
      body: '{}', contentType: 'application/json');

  if (r['code'] != 200) {
    print('ERROR: rpc fn_verify_audit_triggers failed (HTTP ${r['code']})');
    print('  ${r['raw']}');
    print('  => The migration has NOT been applied yet, or it failed.');
    print('  => Paste database/migrations/supabase_migration_audit_log.sql '
        'into the SQL Editor and run it first.');
    return;
  }

  final rows = (r['body'] as List).cast<Map<String, dynamic>>();
  if (rows.isEmpty) {
    print('No rows returned - unexpected.');
    return;
  }

  var ok = 0;
  print('${'Table'.padRight(22)} ${'Trigger'.padRight(9)} AuditRows');
  for (final row in rows) {
    final t = (row['table_name'] ?? '').toString().padRight(22);
    final has = row['has_trigger'] == true;
    final count = (row['rows_in_audit'] ?? 0);
    if (has) ok++;
    print('$t ${(has ? 'YES' : 'NO ').padRight(9)} $count');
  }
  print('---');
  print(ok == 10
      ? 'ALL 10 triggers present. Logging is armed.'
      : 'WARNING: only $ok/10 triggers present. '
          'Re-run the migration; logging is INCOMPLETE.');
  print('Hint: after verifying, run the follow-up RLS file to hard-lock logs.');
}

/// Read-only GAP CHECK: every record in `records` must have a matching
/// `insert` audit row (client-logged full tuple; records are no longer logged
/// by the DB trigger). Prints the count of records with no logged insert.
/// A non-zero gap means the AuditReconciler would repair those records.
Future<Set<int>> _pagedIds(String path, String select) async {
  final ids = <int>{};
  var offset = 0;
  const pageSize = 1000;
  while (true) {
    final uri = Uri.parse('$url$path').replace(queryParameters: {
      'select': select,
      'order': 'record_id',
      'limit': '$pageSize',
      'offset': '$offset',
    });
    final r = await _request('GET', '${uri.path}?${uri.query}');
    final page = ((r['body'] ?? []) as List).cast<Map<String, dynamic>>();
    for (final row in page) {
      final rid = row['record_id'];
      if (rid is int) ids.add(rid);
    }
    if (page.length < pageSize) break;
    offset += pageSize;
  }
  return ids;
}

Future<void> verifyRecordGaps() async {
  print('');
  print('=== RECORD INSERT GAP CHECK (read-only) ===');
  final recordIds = await _pagedIds('/rest/v1/records', 'record_id');
  final insertIds = await _pagedFilteredInsertIds();
  final gaps = recordIds.where((id) => !insertIds.contains(id)).toList()
    ..sort();
  print('Records: ${recordIds.length}   '
      'With logged insert: ${insertIds.length}   '
      'Gaps: ${gaps.length}');
  if (gaps.isNotEmpty) {
    print('  -> Gap record_ids: ${(gaps.take(20).toList())}'
        '${gaps.length > 20 ? ' (…)' : ''}');
    print('  -> The AuditReconciler would repair these (stamped reconciled).');
  } else {
    print('OK: every record has a logged insert. No gaps.');
  }
}

Future<Set<int>> _pagedFilteredInsertIds() async {
  final ids = <int>{};
  var offset = 0;
  const pageSize = 1000;
  while (true) {
    final uri = Uri.parse('$url/rest/v1/audit_log').replace(queryParameters: {
      'select': 'record_id',
      'table_name': 'eq.records',
      'action': 'eq.insert',
      'order': 'record_id',
      'limit': '$pageSize',
      'offset': '$offset',
    });
    final r = await _request('GET', '${uri.path}?${uri.query}');
    final page = ((r['body'] ?? []) as List).cast<Map<String, dynamic>>();
    for (final row in page) {
      final rid = row['record_id'];
      if (rid is int && rid != 0) ids.add(rid);
    }
    if (page.length < pageSize) break;
    offset += pageSize;
  }
  return ids;
}

Future<void> burnTest() async {
  print('');
  print('=== LIVE SMOKE TEST (writes data; clean up after) ===');
  final name = '_audit_probe_${DateTime.now().millisecondsSinceEpoch}';

  // 1) INSERT a temp artist (triggers fn_audit_log -> audit row).
  final ins = await _request('POST', '/rest/v1/artists',
      body: jsonEncode({'artist_name': name}),
      contentType: 'application/json');
  print('INSERT artist -> HTTP ${ins['code']}');
  if (ins['code'] < 200 || ins['code'] >= 300) {
    print('  insert failed: ${ins['raw']}');
    return;
  }
  final artistId =
      (ins['body'] is List ? ins['body'][0] : ins['body'])?['artist_id'];

  // 2) Fetch most recent audit rows to see if our artist insert was logged.
  final q = Uri.parse('$url/rest/v1/audit_log')
      .replace(queryParameters: {
        'select': '*',
        'table_name': 'eq.artists',
        'order': 'created_at.desc',
        'limit': '5',
      });
  final audit = await _request('GET', '${q.path}?${q.query}');
  final entries = (audit['body'] as List).cast<Map<String, dynamic>>();
  final match = entries.where((e) =>
      e['action'] == 'insert' &&
      e['table_name'] == 'artists' &&
      e['record_id'] == artistId).toList();
  print('Audit rows for artists (recent): ${entries.length}');
  print(match.isNotEmpty
      ? 'PASS: audit insert row found (record_id=$artistId) '
          'origin_tab=${match.first['origin_tab']} device=${match.first['device']}'
      : 'FAIL: no audit insert row found for artist $artistId '
          '(only ${entries.length} recent rows)');

  // 3) Clean up the temp artist (+ its audit delete row is expected).
  if (artistId != null) {
    final del = await _request(
        'DELETE', '/rest/v1/artists?artist_id=eq.$artistId');
    print('DELETE artist -> HTTP ${del['code']}');
  }
}

void main(List<String> args) async {
  _requireEnv();
  await verifyTriggers();
  if (args.contains('--burn')) await burnTest();
  if (!args.contains('--burn')) await verifyRecordGaps();
}
