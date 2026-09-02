import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';

/// DB-free probing of the full-database import field contract: record type
/// queue, artists Proceed/Auto-Fix, genre/descriptor Skip Tuple, silent
/// streaming/url count handling, and validated record-skips.
///
/// A fresh [ManageProvider] holds empty in-memory entity lists, so artists/
/// genres/etc. never hit the database. For full-DB the existing-record fetch
/// is bypassed with [ManageProvider.debugSetExistingRecordNorms].
///
/// Subcase index (label -> what it pins):
/// ---------------------------------------------------------------
///  #   area               label
///  1   recordType         blank type is valid, no queue
///  2   recordType         canonical + case-variant types are valid
///  3   recordType         non-matching type -> one Record Type Invalid item
///  4   recordType         proceed blanks the type cell
///  5   recordType         rectify sets the chosen canonical type
///  6   recordType         type queue resolves before the artist queue
///  7   artists            one item per bad artist, siblings not queued
///  8   artists            proceed drops only the bad entry, keeps siblings
///  9   artists            auto-fix drops the bad entry (same effect)
/// 10   artists            skip tuple blanks the record name
/// 11   genres             skip tuple blanks the genre-name column
/// 12   descriptors        skip tuple blanks the descriptor-name column
/// 13   streaming          unrecognized name -> Streaming Warning queue
/// 14   streaming/url      names > urls is valid (no separator warning)
/// 15   streaming/url      urls > names silently counted as extra URLs
/// 16   record-skip        blank name rows are validated skips, reason shown
/// 17   record-skip        duplicate-in-file rows are validated skips
/// 18   record-skip        already-in-DB rows are validated skips
/// 19   status             invalid status silently defaults, counted only
/// ---------------------------------------------------------------
void main() {
  test('full database import warnings (19 subcases)', () async {
    var ran = 0;

    Future<void> sub(String label, FutureOr<void> Function() body) async {
      ran++;
      try {
        await body();
      } catch (e) {
        fail('SUB  #$ran  "$label"\n$e');
      }
    }

    /// Resolving the last queue auto-advances into pass 2, which touches the
    /// (absent) database and is normally not awaited by the UI. Wait until
    /// that chain settles so no work outlives the test.
    Future<void> settleImport(ManageProvider p) async {
      for (var i = 0; i < 50 && p.importing; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    Future<ManageProvider> loadAndStart({required String csv}) async {
      final p = ManageProvider();
      p.debugSetExistingRecordNorms({});
      p.setImportEntityTypeSelection(ImportEntityType.fullDatabase);
      await p.loadImportFile(csv, 'probe.csv');
      await p.startImport();
      return p;
    }

    const headers =
        'record_name,type,artists,genres,descriptors,streaming,url,release_date,status\n';

    // --- recordType -------------------------------------------------------
    await sub('1 blank type is valid, no queue', () async {
      final p = await loadAndStart(csv: '${headers}r1,,A1,,,,,,\n');
      expect(p.recordTypeInvalidQueue, isEmpty);
      expect(p.importValid, 1);
      await settleImport(p);
    });

    await sub('2 canonical + case-variant types are valid', () async {
      final p = await loadAndStart(
          csv: '${headers}r1,Album,,,,,,\nr2,  EP  ,,,,,,\nr3,MIXTAPE,,,,,,\n');
      expect(p.recordTypeInvalidQueue, isEmpty);
      expect(p.importValid, 3);
      await settleImport(p);
    });

    await sub('3 non-matching type -> one Record Type Invalid item',
        () async {
      final p = await loadAndStart(csv: '${headers}r1,albumsss,,,,,,\n');
      expect(p.recordTypeInvalidQueue, hasLength(1));
      expect(p.recordTypeInvalidQueue.first.recordName, 'r1');
      expect(p.recordTypeInvalidQueue.first.rawValue, 'albumsss');
      expect(p.importPhase, ImportPhase.rectification);
      expect(p.activeWarningQueue, 'recordTypeInvalid');
      await settleImport(p);
    });

    await sub('4 proceed blanks the type cell', () async {
      final p = await loadAndStart(csv: '${headers}r1,albumsss,,,,,,\n');
      p.proceedRecordTypeInvalid();
      expect(p.recordTypeInvalidIndex, 1);
      expect(p.importModifiedRows[0]!, contains(''));
      await settleImport(p);
    });

    await sub('5 rectify sets the chosen canonical type', () async {
      final p = await loadAndStart(csv: '${headers}r1,albumsss,,,,,,\n');
      p.rectifyRecordTypeInvalid('Album');
      expect(p.recordTypeInvalidIndex, 1);
      expect(p.importModifiedRows[0]!, contains('Album'));
      await settleImport(p);
    });

    await sub('6 type queue resolves before the artist queue', () async {
      final p = await loadAndStart(csv: '${headers}r1,albumsss,NobodyHere,,,,,,\n');
      expect(p.activeWarningQueue, 'recordTypeInvalid');
      expect(p.recordTypeInvalidQueue, hasLength(1));
      expect(p.artistMismatchQueue, hasLength(1));
      p.proceedRecordTypeInvalid();
      expect(p.activeWarningQueue, 'artistMismatch');
      await settleImport(p);
    });

    // --- artists ----------------------------------------------------------
    await sub('7 one item per bad artist, siblings not queued', () async {
      final p = await loadAndStart(csv: '${headers}r1,,NobodyHere,GreenDay,,,,,\n');
      expect(p.artistMismatchQueue, hasLength(1));
      expect(p.artistMismatchQueue.first.csvArtistName, 'NobodyHere');
      await settleImport(p);
    });

    await sub('8 proceed drops only the bad entry, keeps siblings', () async {
      final p = await loadAndStart(csv: '${headers}r1,,NobodyHere|RealOne,,,,,\n');
      p.proceedArtistMismatch();
      expect(p.artistMismatchIndex, 1);
      expect(p.importModifiedRows[0]!, contains('RealOne'));
      expect(p.importModifiedRows[0]!, isNot(contains('NobodyHere')));
      await settleImport(p);
    });

    await sub('9 auto-fix drops the bad entry (same effect)', () async {
      final p = await loadAndStart(csv: '${headers}r1,,NobodyHere|RealOne,,,,,\n');
      p.autoFixArtistMismatch();
      expect(p.artistMismatchIndex, 1);
      expect(p.importModifiedRows[0]!, contains('RealOne'));
      expect(p.importModifiedRows[0]!, isNot(contains('NobodyHere')));
      await settleImport(p);
    });

    await sub('10 skip tuple blanks the record name', () async {
      final p = await loadAndStart(csv: '${headers}r1,,NobodyHere,,,,,\n');
      p.skipArtistMismatchTuple();
      expect(p.artistMismatchQueue.first.skipped, isTrue);
      expect(p.skippedTupleRowIndexes, contains(0));
      expect(p.importModifiedRows[0]![0], '');
      await settleImport(p);
    });

    // --- genre / descriptor skip tuple ------------------------------------
    await sub('11 skip tuple blanks the genre-name column', () async {
      final p = await loadAndStart(csv: '${headers}r1,,,NotAGenre,,,,\n');
      expect(p.genreMismatchQueue, hasLength(1));
      p.skipGenreMismatchTuple();
      expect(p.genreMismatchQueue.first.skipped, isTrue);
      expect(p.skippedTupleRowIndexes, contains(0));
      expect(p.importModifiedRows[0]![0], '');
      await settleImport(p);
    });

    await sub('12 skip tuple blanks the descriptor-name column', () async {
      final p = await loadAndStart(csv: '${headers}r1,,,,NotADesc,,,,\n');
      expect(p.descMismatchQueue, hasLength(1));
      p.skipDescMismatchTuple();
      expect(p.descMismatchQueue.first.skipped, isTrue);
      expect(p.skippedTupleRowIndexes, contains(0));
      expect(p.importModifiedRows[0]![0], '');
      await settleImport(p);
    });

    // --- streaming / url ---------------------------------------------------
    await sub('13 unrecognized name -> Streaming Warning queue', () async {
      final p = await loadAndStart(csv: '${headers}r1,,,,,Foo,http://x,\n');
      expect(p.streamingWarningQueue, hasLength(1));
      expect(p.streamingWarningQueue.first.unrecognizedNames, ['Foo']);
      expect(p.separatorWarningQueue, isEmpty);
      await settleImport(p);
    });

    await sub('14 names > urls is valid (no separator warning)', () async {
      final p =
          await loadAndStart(csv: '${headers}r1,,,,,spotify|youtube,http://a,\n');
      expect(p.separatorWarningQueue, isEmpty);
      expect(p.streamingWarningQueue, isEmpty);
      expect(p.extraUrlRows, 0);
      await settleImport(p);
    });

    await sub('15 urls > names silently counted as extra URLs', () async {
      final p =
          await loadAndStart(csv: '${headers}r1,,,,,spotify,http://a|http://b,\n');
      expect(p.separatorWarningQueue, isEmpty);
      expect(p.streamingWarningQueue, isEmpty);
      expect(p.extraUrlRows, 1);
      await settleImport(p);
    });

    // --- record skips ------------------------------------------------------
    await sub('16 blank name rows are validated skips, reason shown',
        () async {
      final p = await loadAndStart(csv: '$headers,x\n');
      expect(p.recordSkipCount, 1);
      expect(p.validatedSkipRowIndexes, contains(0));
      expect(p.skippedRecords, hasLength(1));
      expect(p.skippedRecords.first.reason, 'Empty name');
      expect(p.importPhase, ImportPhase.summary);
    });

    await sub('17 duplicate-in-file rows are validated skips', () async {
      final p = await loadAndStart(csv: '${headers}r1,,,,,,\nr1,,,,,,\n');
      expect(p.importValid, 1);
      expect(p.recordSkipCount, 1);
      expect(p.validatedSkipRowIndexes, contains(1));
      p.debugBuildImportSummary();
      expect(p.skippedRecords, hasLength(1));
      expect(p.skippedRecords.first.reason, 'Duplicate within the file');
      expect(p.importedRecords, hasLength(1));
      await settleImport(p);
    });

    await sub('18 already-in-DB rows are validated skips', () async {
      final p = ManageProvider();
      p.debugSetExistingRecordNorms({'Existing One'});
      p.setImportEntityTypeSelection(ImportEntityType.fullDatabase);
      await p.loadImportFile('${headers}Existing One,,,,,,\n', 'probe.csv');
      await p.startImport();
      expect(p.recordSkipCount, 1);
      expect(p.validatedSkipRowIndexes, contains(0));
      p.debugBuildImportSummary();
      expect(p.skippedRecords.first.reason, 'Already in the database');
      expect(p.importPhase, ImportPhase.summary);
    });

    // --- status ------------------------------------------------------------
    await sub('19 invalid status silently defaults, counted only', () async {
      final p = await loadAndStart(csv: '${headers}r1,,,,,,,2024,weird\n');
      expect(p.statusWarningCount, 1);
      expect(p.importValid, 1);
      await settleImport(p);
    });

    expect(ran, 19, reason: 'all 19 subcases must run');
  });
}