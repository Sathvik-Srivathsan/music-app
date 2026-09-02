import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/statistics/domain/audit_log_sentence.dart';
import 'package:music_collection/shared/models/audit_log.dart';

void main() {
  AuditLog log({
    required String action,
    required String table,
    Map<String, dynamic>? details,
  }) {
    return AuditLog(action: action, tableName: table, details: details);
  }

  test('record insert renders labelled sentence', () {
    final l = log(
      action: 'insert',
      table: 'records',
      details: {
        'inserted': {'record_id': 5, 'record_name': 'Kind of Blue'},
      },
    );
    expect(AuditLogSentence.build(l), 'Added record "Kind of Blue".');
  });

  test('artist delete renders labelled sentence', () {
    final l = log(
      action: 'delete',
      table: 'artists',
      details: {
        'deleted': {'artist_id': 3, 'artist_name': 'Miles Davis'},
      },
    );
    expect(AuditLogSentence.build(l), 'Deleted artist "Miles Davis".');
  });

  test('update shows only changed non-id fields', () {
    final l = log(
      action: 'update',
      table: 'records',
      details: {
        'before': {'record_id': 5, 'record_name': 'A', 'status': 'false'},
        'after': {'record_id': 5, 'record_name': 'A', 'status': 'true'},
      },
    );
    final s = AuditLogSentence.build(l);
    expect(s, startsWith('Updated record "A".'));
    expect(s, contains('status: false → true'));
    // id never appears
    expect(s, isNot(contains('5')));
  });

  test('junction row with no name uses generic label', () {
    final l = log(
      action: 'insert',
      table: 'genre_hierarchy',
      details: {
        'inserted': {'parent_genre_id': 1, 'child_genre_id': 2},
      },
    );
    expect(AuditLogSentence.build(l), 'Added a genre hierarchy link.');
  });

  test('import aggregates render counts', () {
    final l = log(
      action: 'import_records',
      table: 'records',
      details: {
        'records': 12,
        'artist_links': 8,
        'genre_links': 9,
      },
    );
    expect(
      AuditLogSentence.build(l),
      'Imported 12 records (artist_links: 8, genre_links: 9) from CSV.',
    );
  });

  test('app boot renders device', () {
    final l = log(action: 'app_boot', table: 'audit_log', details: {
      'device': 'web',
    });
    expect(AuditLogSentence.build(l), 'App started on web.');
  });

  test('empty details falls back without crashing', () {
    final l = log(action: 'weird', table: 'some_table', details: {});
    expect(AuditLogSentence.build(l), 'weird on some_table.');
  });

  test('fallback hides id-looking keys', () {
    final l = log(
      action: 'weird',
      table: 'some_table',
      details: {'record_id': 1, 'name': 'X'},
    );
    final s = AuditLogSentence.build(l);
    expect(s, isNot(contains('record_id')));
    expect(s, contains('name: X'));
  });

  test('client full-tuple update shows whole-list changes', () {
    final l = log(
      action: 'update',
      table: 'records',
      details: {
        'before': {
          'record_name': 'Kind of Blue',
          'status': false,
          'genres': ['Jazz', 'Blues'],
        },
        'after': {
          'record_name': 'Kind of Blue',
          'status': false,
          'genres': ['Jazz', 'Modal'],
        },
      },
    );
    final s = AuditLogSentence.build(l);
    expect(s, startsWith('Updated record "Kind of Blue".'));
    expect(
        s, contains('genres: [Jazz, Blues] \u2192 [Jazz, Modal]'));
  });

  test('client full-tuple insert renders from the inserted map', () {
    final l = log(
      action: 'insert',
      table: 'records',
      details: {
        'inserted': {
          'record_name': 'Blue Train',
          'artists': ['John Coltrane'],
        },
      },
    );
    expect(AuditLogSentence.build(l), 'Added record "Blue Train".');
  });

  test('formattedTime shows Indian Standard Time (UTC+5:30) regardless of device',
      () {
    final l = AuditLog(
      logId: 1,
      action: 'insert',
      tableName: 'records',
      createdAt: DateTime.parse('2026-08-29T00:00:00Z'),
    );
    expect(l.formattedTime, '05:30:00 29/08/2026');
  });

  test('formattedTime adds 5h30m across a date boundary', () {
    final l = AuditLog(
      logId: 2,
      action: 'update',
      tableName: 'artists',
      createdAt: DateTime.parse('2026-08-28T20:00:00Z'),
    );
    expect(l.formattedTime, '01:30:00 29/08/2026');
  });

  test('formattedTime handles an offset-less (naive) UTC parse', () {
    final l = AuditLog(
      logId: 3,
      action: 'insert',
      tableName: 'records',
      createdAt: DateTime.parse('2026-08-29T00:00:00'),
    );
    expect(l.formattedTime, '05:30:00 29/08/2026');
  });
}
