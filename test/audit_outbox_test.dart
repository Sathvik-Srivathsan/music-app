import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/logging/audit_outbox.dart';

/// A tiny in-memory store shared by the injected load/save closures.
class _MemStore {
  String? raw;
}

AuditOutbox _build(
  _MemStore store, {
  OutboxWriteEntry? writeEntry,
  LoggedOpIdsFetcher? loggedOpIds,
}) {
  return AuditOutbox(
    load: () async => store.raw,
    save: (json) async => store.raw = json,
    writeEntry: writeEntry ??
        ({required action, required recordId, required originTab, required details, required opId}) async {},
    loggedOpIds: loggedOpIds ?? () async => <String>{},
  );
}

void main() {
  group('AuditOutbox.enqueue', () {
    test('queues an entry with a generated op_id and updates pendingCount',
        () async {
      final store = _MemStore();
      final box = _build(store);

      final opId = await box.enqueue(
        action: 'update',
        details: {'before': {'genres': ['A']}, 'after': {'genres': ['A', 'B']}},
        recordId: 7,
        originTab: 'search',
      );

      expect(opId, isNotEmpty);
      expect(opId, startsWith('op_'));
      expect(box.pendingCount, 1);

      final pending = await box.readPending();
      expect(pending, hasLength(1));
      expect(pending.first['op_id'], opId);
      expect(pending.first['record_id'], 7);
      expect(pending.first['origin_tab'], 'search');
      expect(pending.first['action'], 'update');
    });

    test('does not throw when storage fails (best-effort)', () async {
      final box = AuditOutbox(
        load: () async => throw Exception('read fail'),
        save: (json) async => throw Exception('save fail'),
        writeEntry: ({required action, required recordId, required originTab, required details, required opId}) async {},
        loggedOpIds: () async => <String>{},
      );
      await expectLater(
        box.enqueue(
          action: 'insert',
          details: const {'inserted': {'record_name': 'R'}},
          recordId: 1,
          originTab: 'search',
        ),
        completes,
      );
    });
  });

  group('AuditOutbox.flush', () {
    test('writes pending entries and prunes them on success', () async {
      final wrote = <String>[];
      final store = _MemStore();
      final box = _build(
        store,
        writeEntry: ({required action, required recordId, required originTab, required details, required opId}) async {
          wrote.add(opId);
          expect(details['_op_id'], opId, reason: 'entry stamped with its op_id');
        },
      );

      final op1 = await box.enqueue(
          action: 'update',
          details: {'before': {}, 'after': {}},
          recordId: 1,
          originTab: 'search');
      final op2 = await box.enqueue(
          action: 'delete',
          details: {'deleted': {}},
          recordId: 2,
          originTab: 'search');

      final written = await box.flush();

      expect(written, 2);
      expect(wrote, containsAll([op1, op2]));
      expect(box.pendingCount, 0);
      expect(await box.readPending(), isEmpty);
    });

    test('skips entries whose op_id already landed (logged) and prunes them',
        () async {
      final wrote = <String>[];
      var logged = <String>{};
      final store = _MemStore();
      final box = _build(
        store,
        writeEntry: ({required action, required recordId, required originTab, required details, required opId}) async {
          wrote.add(opId);
        },
        loggedOpIds: () async => Set.of(logged),
      );

      final op1 = await box.enqueue(
          action: 'insert',
          details: {'inserted': {}},
          recordId: 5,
          originTab: 'search');
      final op2 = await box.enqueue(
          action: 'update',
          details: {'before': {}, 'after': {}},
          recordId: 6,
          originTab: 'search');

      // Simulate: op1's log already landed before the local remove.
      logged = {op1};
      final written = await box.flush();

      expect(written, 1);
      expect(wrote, [op2], reason: 'only op2 was freshly written');
      expect(await box.readPending(), isEmpty,
          reason: 'confirmed op1 pruned, op2 written+pruned');
    });

    test('keeps entries whose write fails, then retries on next flush', () async {
      var failFirst = true;
      final wrote = <String>[];
      final store = _MemStore();
      final box = _build(
        store,
        writeEntry: ({required action, required recordId, required originTab, required details, required opId}) async {
          if (failFirst) {
            failFirst = false;
            throw Exception('network down');
          }
          wrote.add(opId);
        },
      );

      await box.enqueue(
          action: 'delete',
          details: {'deleted': {}},
          recordId: 3,
          originTab: 'search');

      // First flush: write throws -> entry stays queued.
      var written = await box.flush();
      expect(written, 0);
      expect(wrote, isEmpty);
      expect(box.pendingCount, 1);
      expect(await box.readPending(), hasLength(1));

      // Second flush (next launch): write succeeds -> pruned.
      written = await box.flush();
      expect(written, 1);
      expect(wrote, hasLength(1));
      expect(box.pendingCount, 0);
      expect(await box.readPending(), isEmpty);
    });

    test('flush is idempotent after success (second flush is a no-op)',
        () async {
      var writes = 0;
      final store = _MemStore();
      final box = _build(
        store,
        writeEntry: ({required action, required recordId, required originTab, required details, required opId}) async {
          writes++;
        },
      );

      await box.enqueue(
          action: 'insert',
          details: {'inserted': {}},
          recordId: 4,
          originTab: 'search');

      expect(await box.flush(), 1);
      expect(await box.flush(), 0);
      expect(writes, 1);
    });
  });
}
