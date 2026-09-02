import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';

/// DB-free coverage of the standalone genre/descriptor import decision logic.
///
/// A fresh [ManageProvider] holds empty in-memory lists, so validation never
/// hits the database. These tests pin down behaviours that previous bugs in
/// this layer had to be discovered by manual testing.
void main() {
  /// Resolving the last tuple auto-advances into pass 2, which touches the
  /// (absent) database and is normally not awaited by the UI. Wait until that
  /// chain settles so no work outlives the test.
  Future<void> settleImport(ManageProvider p) async {
    for (var i = 0; i < 50 && p.importing; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<ManageProvider> loadAndStart({
    required ImportEntityType type,
    required String csv,
  }) async {
    final p = ManageProvider();
    p.setImportEntityTypeSelection(type);
    await p.loadImportFile(csv, 'test.csv');
    await p.startImport();
    return p;
  }

  group('skipParentNotFoundTuple (standalone genre/descriptor)', () {
    test('blanks the genre column when the header is genres,parent', () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres, csv: 'genres,parent\nfoo,scene\n');

      expect(p.parentNotFoundQueue, hasLength(1));
      expect(p.importPhase, ImportPhase.rectification);

      p.skipParentNotFoundTuple();

      expect(p.parentNotFoundQueue.first.skipped, isTrue);
      expect(p.skippedTupleRowIndexes, contains(0));
      expect(p.parentNotFoundIndex, 1);
      expect(p.importModifiedRows[0], ['', 'scene']);

      await settleImport(p);
    });

    test('blanks the descriptor column when the header is descriptors,parent',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.descriptors, csv: 'descriptors,parent\nfoo,scene\n');

      expect(p.parentNotFoundQueue, hasLength(1));

      p.skipParentNotFoundTuple();

      expect(p.parentNotFoundQueue.first.skipped, isTrue);
      expect(p.skippedTupleRowIndexes, contains(0));
      expect(p.importModifiedRows[0], ['', 'scene']);

      await settleImport(p);
    });

    test('multiple tuples skip independently in order', () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres, csv: 'genres,parent\nfoo,scene\nbar,other\n');

      expect(p.parentNotFoundQueue, hasLength(2));

      p.skipParentNotFoundTuple();
      expect(p.importModifiedRows[0], ['', 'scene']);

      p.skipParentNotFoundTuple();
      expect(p.importModifiedRows[1], ['', 'other']);
      expect(p.parentNotFoundIndex, 2);
      expect(p.skippedTupleRowIndexes, {0, 1});

      await settleImport(p);
    });
  });

  group('rectifyParentNotFound (standalone genre/descriptor)', () {
    test('rectifying to root clears the parent column but keeps the name',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres, csv: 'genres,parent\nbar,scene\n');

      expect(p.parentNotFoundQueue, hasLength(1));

      p.rectifyParentNotFound(null);

      expect(p.parentNotFoundQueue.first.skipped, isFalse);
      expect(p.importModifiedRows[0], ['bar', '']);
      expect(p.parentNotFoundIndex, 1);

      await settleImport(p);
    });
  });

  group('summary reporting of skipped tuples', () {
    test('a skipped tuple is not reported as an (empty) skipped record',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres, csv: 'genres,parent\nfoo,scene\n');

      p.skipParentNotFoundTuple();
      p.debugBuildImportSummary();

      expect(p.skippedRecords.where((s) => s.recordName == '(empty)'), isEmpty);
      expect(p.importedRecords, isEmpty);

      await settleImport(p);
    });
  });
}