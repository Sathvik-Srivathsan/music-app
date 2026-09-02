import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/logging/audit_reconciler.dart';
import 'package:music_collection/features/search/data/repositories/search_repository.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';

String _todayDmy() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year}';
}

RecordDetails _row(int id, {String name = 'R', String? dateAdded}) {
  return RecordDetails(
    record: Record(
      recordId: id,
      recordName: '$name $id',
      dateAdded: dateAdded ?? _todayDmy(),
    ),
    artists: [Artist(artistName: 'A')],
    genres: [Genre(genreName: 'G')],
    descriptors: [Descriptor(descriptorName: 'D')],
    streaming: [StreamingService(serviceName: 'Spotify', serviceUrl: '')],
  );
}

FetchResult _result(List<RecordDetails> rows) =>
    FetchResult(rows, const [], genreEdges: const [], descriptorEdges: const []);

void main() {
  group('AuditReconciler.reconcile', () {
    test('repairs records with no logged insert and stamps reconciled=true',
        () async {
      final rows = [_row(1), _row(2)];
      final loggedFuture = Future<Set<int>>.value(<int>{});
      final logged = <(int, String)>[];
      final c = AuditReconciler(
        fetchRecords: () async => _result(rows),
        fetchLoggedInsertRecordIds: () => loggedFuture,
        logRecord: (details, tab, {String action = 'insert'}) async {
          logged.add((details.record.recordId!, action));
        },
        originTab: 'reconciler',
      );

      final repaired = await c.reconcile();
      expect(repaired, containsAll([1, 2]));
      expect(logged.length, 2);
      expect(logged, contains((1, 'insert')));
      expect(logged, contains((2, 'insert')));
    });

    test('skips records that already have a logged insert', () async {
      final rows = [_row(1), _row(2)];
      final c = AuditReconciler(
        fetchRecords: () async => _result(rows),
        fetchLoggedInsertRecordIds: () async => {2},
        logRecord: (details, tab, {String action = 'insert'}) async {},
      );

      final repaired = await c.reconcile();
      expect(repaired, [1]);
    });

    test('skips legacy records created before reconcileSince', () async {
      final rows = [
        _row(1, dateAdded: '01/01/2020'),
        _row(2, dateAdded: _todayDmy()),
      ];
      final c = AuditReconciler(
        fetchRecords: () async => _result(rows),
        fetchLoggedInsertRecordIds: () async => <int>{},
        logRecord: (details, tab, {String action = 'insert'}) async {},
      );

      final repaired = await c.reconcile();
      expect(repaired, [2]);
    });

    test('skips records with unparseable date_added (defensive)', () async {
      final rows = [_row(1, dateAdded: 'nonsense')];
      final c = AuditReconciler(
        fetchRecords: () async => _result(rows),
        fetchLoggedInsertRecordIds: () async => <int>{},
        logRecord: (details, tab, {String action = 'insert'}) async {},
      );

      expect(await c.reconcile(), isEmpty);
    });

    test('swallows a throwing log call and keeps going', () async {
      final rows = [_row(1), _row(2)];
      final c = AuditReconciler(
        fetchRecords: () async => _result(rows),
        fetchLoggedInsertRecordIds: () async => <int>{},
        logRecord: (details, tab, {String action = 'insert'}) async {
          if (details.record.recordId == 1) {
            throw Exception('network');
          }
        },
      );

      final repaired = await c.reconcile();
      expect(repaired, [2]);
    });

    test('returns empty when fetch fails (nothing repaired)', () async {
      final c = AuditReconciler(
        fetchRecords: () async => throw Exception('core read failed'),
        fetchLoggedInsertRecordIds: () async => <int>{},
        logRecord: (details, tab, {String action = 'insert'}) async {},
      );

      expect(await c.reconcile(), isEmpty);
    });

    test('is idempotent across runs (a repaired id becomes logged)', () async {
      var loggedIds = <int>{};
      final c = AuditReconciler(
        fetchRecords: () async => _result([_row(1)]),
        fetchLoggedInsertRecordIds: () async => Set.of(loggedIds),
        logRecord: (details, tab, {String action = 'insert'}) async {
          loggedIds.add(details.record.recordId!);
        },
      );

      expect(await c.reconcile(), [1]);
      expect(await c.reconcile(), isEmpty);
    });
  });
}
