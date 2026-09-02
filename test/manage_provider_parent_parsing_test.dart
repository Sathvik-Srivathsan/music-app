import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';

/// ONE probing test covering the parent-column parsing design end to end, as
/// 28 labelled subcases so it can be read and documented as a spec.
///
/// A fresh [ManageProvider] holds empty in-memory lists, so validation never
/// hits the database and nothing needs cleanup. See the subcase index below.
///
/// Subcase index (label -> what it pins):
/// ---------------------------------------------------------------
///  #  area              label
///  1  parse             blank / whitespace cell is empty (root)
///  2  parse             separator-only cells collapse to empty
///  3  parse             single unknown token is one token, not mixed
///  4  parse             leading/trailing separators trim to clean token
///  5  parse             comma list splits (no mixed flag)
///  6  parse             pipe list splits (no mixed flag)
///  7  parse             ragged spacing + interior empties collapse
///  8  parse             duplicate tokens dedupe case-insensitively
///  9  parse             mixed separators flagged, tokens still extracted
/// 10  replaceToken      replaces only the missing token, keeps known tokens
/// 11  replaceToken      replaces the sole token
/// 12  replaceToken      case-insensitive match of the missing token
/// 13  replaceToken      appends when the token is absent from the cell
/// 14  resolveEdges      resolves every known token to an edge
/// 15  resolveEdges      drops missing parents and self-parents
/// 16  resolveEdges      skips rows whose name never resolved to an id
/// 17  genre flow        separator-only parent imports as root, no warning
/// 18  genre flow        single unknown parent -> one parent-not-found item
/// 19  genre flow        leading/trailing-separator cells report clean tokens
/// 20  genre flow        mixed separators -> separator queue as parent field
/// 21  genre flow        pipe multi-parent -> one item per token
/// 22  desc flow         separator-only parent imports as root, no warning
/// 23  desc flow         mixed separators -> separator queue as parent field
/// 24  desc flow         single unknown parent -> one parent-not-found item
/// 25  desc flow         pipe multi-parent -> one item per token (parity)
/// 26  rectification     proceed clears the parent cell, keeps the name
/// 27  rectification     skip blanks the genre name column
/// 28  rectification     skip blanks the descriptor name column (parity)
/// ---------------------------------------------------------------
void main() {
  test('parent column probing (28 subcases)', () async {
    var ran = 0;

    Future<void> sub(String label, FutureOr<void> Function() body) async {
      ran++;
      try {
        await body();
      } catch (e) {
        fail('SUB  #$ran  "$label"\n$e');
      }
    }

    /// Resolving the last tuple auto-advances into pass 2, which touches the
    /// (absent) database and is normally not awaited by the UI. Wait until
    /// that chain settles so no work outlives the test.
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
      await p.loadImportFile(csv, 'probe.csv');
      await p.startImport();
      return p;
    }

    // --- parseParentCell -------------------------------------------------
    ParentCellParseResult parse(String cell) =>
        ManageProvider.parseParentCell(cell);

    await sub('1 blank / whitespace cell is empty (root)', () {
      expect(parse('').empty, isTrue);
      expect(parse('   ').empty, isTrue);
    });

    await sub('2 separator-only cells collapse to empty', () {
      for (final cell in [',,,,,,', '||||||||', '|', ',,,']) {
        final r = parse(cell);
        expect(r.empty, isTrue, reason: 'cell "$cell"');
        expect(r.mixed, isFalse, reason: 'cell "$cell"');
      }
    });

    await sub('3 single unknown token is one token, not mixed', () {
      final r = parse('uisbgkjsfgks');
      expect(r.tokens, ['uisbgkjsfgks']);
      expect(r.mixed, isFalse);
      expect(r.empty, isFalse);
    });

    await sub('4 leading/trailing separators trim to clean token', () {
      expect(parse(', uisbgkjsfgks').tokens, ['uisbgkjsfgks']);
      expect(parse('skudfgbsdjfg,').tokens, ['skudfgbsdjfg']);
    });

    await sub('5 comma list splits (no mixed flag)', () {
      final r = parse('rock, punk');
      expect(r.tokens, ['rock', 'punk']);
      expect(r.mixed, isFalse);
    });

    await sub('6 pipe list splits (no mixed flag)', () {
      final r = parse('rock||punk');
      expect(r.tokens, ['rock', 'punk']);
      expect(r.mixed, isFalse);
    });

    await sub('7 ragged spacing + interior empties collapse', () {
      expect(parse('  rock  ,  punk  ').tokens, ['rock', 'punk']);
      expect(parse(',,rock,,').tokens, ['rock']);
      expect(parse('rock, ,punk').tokens, ['rock', 'punk']);
    });

    await sub('8 duplicate tokens dedupe case-insensitively', () {
      expect(parse('rock, rock').tokens, ['rock']);
      expect(parse('Rock, rock').tokens, ['Rock']);
    });

    await sub('9 mixed separators flagged, tokens still extracted', () {
      final r = parse('kjsdafjksf,skdufhgskjfg||||sjybg,,,,||||sdfgjn,|,|');
      expect(r.mixed, isTrue);
      expect(r.tokens, ['kjsdafjksf', 'skdufhgskjfg', 'sjybg', 'sdfgjn']);

      final r2 = parse('rock,|punk');
      expect(r2.mixed, isTrue);
      expect(r2.tokens, ['rock', 'punk']);
    });

    // --- replaceParentToken ---------------------------------------------
    const replace = ManageProvider.replaceParentToken;

    await sub('10 replaces only the missing token, keeps known tokens', () {
      expect(replace('rock|missing', 'missing', 'Punk'), 'rock, Punk');
      expect(replace('rock, punk', 'punk', 'Metal'), 'rock, Metal');
    });

    await sub('11 replaces the sole token', () {
      expect(replace('missing', 'missing', 'Punk'), 'Punk');
    });

    await sub('12 case-insensitive match of the missing token', () {
      expect(replace('Rock', 'rock', 'Punk'), 'Punk');
    });

    await sub('13 appends when the token is absent from the cell', () {
      expect(replace('rock', 'ghost', 'Punk'), 'rock, Punk');
    });

    // --- resolveHierarchyEdges -------------------------------------------
    await sub('14 resolves every known token to an edge', () {
      final edges = ManageProvider.resolveHierarchyEdges(
        insertedNames: ['child'],
        parentTokens: {
          0: ['rock', 'punk'],
        },
        allNameToId: {
          'child': 10,
          'rock': 1,
          'punk': 2,
        },
      );
      expect(edges, [(1, 10), (2, 10)]);
    });

    await sub('15 drops missing parents and self-parents', () {
      final edges = ManageProvider.resolveHierarchyEdges(
        insertedNames: ['child'],
        parentTokens: {
          0: ['rock', 'ghost', 'child'],
        },
        allNameToId: {
          'child': 10,
          'rock': 1,
        },
      );
      expect(edges, [(1, 10)]);
    });

    await sub('16 skips rows whose name never resolved to an id', () {
      final edges = ManageProvider.resolveHierarchyEdges(
        insertedNames: ['child'],
        parentTokens: {
          0: ['rock'],
        },
        allNameToId: {
          'rock': 1,
        },
      );
      expect(edges, isEmpty);
    });

    // --- standalone genre flows ------------------------------------------
    await sub('17 separator-only parent imports as root, no warning',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres, csv: 'genres,parent\nfoo,,,,,,\n');

      expect(p.separatorWarningQueue, isEmpty);
      expect(p.parentNotFoundQueue, isEmpty);
      expect(p.importModifiedRows, isEmpty);

      await settleImport(p);
    });

    await sub('18 single unknown parent -> one parent-not-found item',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres,
          csv: 'genres,parent\nfoo,uisbgkjsfgks\n');

      expect(p.parentNotFoundQueue, hasLength(1));
      expect(p.parentNotFoundQueue.first.parentName, 'uisbgkjsfgks');
      expect(p.separatorWarningQueue, isEmpty);

      await settleImport(p);
    });

    await sub('19 leading/trailing-separator cells report clean tokens',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres,
          csv: 'genres,parent\nfoo, uisbgkjsfgks\nbar,skudfgbsdjfg,\n');

      expect(p.parentNotFoundQueue.map((e) => e.parentName),
          ['uisbgkjsfgks', 'skudfgbsdjfg']);
      expect(p.parentNotFoundQueue.map((e) => e.childName), ['foo', 'bar']);
      expect(p.separatorWarningQueue, isEmpty);

      await settleImport(p);
    });

    await sub('20 mixed separators -> separator queue as parent field',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres,
          csv: 'genres,parent\nfoo,"kjsdafjksf,skdufhgskjfg||||sjybg"\n');

      expect(p.separatorWarningQueue, hasLength(1));
      expect(p.separatorWarningQueue.first.fieldName, 'parent');
      expect(p.parentNotFoundQueue, isEmpty);
      expect(p.importPhase, ImportPhase.rectification);

      await settleImport(p);
    });

    await sub('21 pipe multi-parent -> one item per token', () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres, csv: 'genres,parent\nfoo,rock||punk\n');

      expect(p.parentNotFoundQueue.map((e) => e.parentName), ['rock', 'punk']);
      expect(p.separatorWarningQueue, isEmpty);
      expect(p.importPhase, ImportPhase.rectification);

      await settleImport(p);
    });

    // --- standalone descriptor flows -------------------------------------
    await sub('22 separator-only parent imports as root, no warning',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.descriptors,
          csv: 'descriptors,parent\nfoo,|||||\n');

      expect(p.separatorWarningQueue, isEmpty);
      expect(p.parentNotFoundQueue, isEmpty);
      expect(p.importModifiedRows, isEmpty);

      await settleImport(p);
    });

    await sub('23 mixed separators -> separator queue as parent field',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.descriptors,
          csv: 'descriptors,parent\nfoo,"rock|, metal"\n');

      expect(p.separatorWarningQueue, hasLength(1));
      expect(p.separatorWarningQueue.first.fieldName, 'parent');
      expect(p.parentNotFoundQueue, isEmpty);

      await settleImport(p);
    });

    await sub('24 single unknown parent -> one parent-not-found item',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.descriptors,
          csv: 'descriptors,parent\nfoo,uisbgkjsfgks\n');

      expect(p.parentNotFoundQueue, hasLength(1));
      expect(p.parentNotFoundQueue.first.parentName, 'uisbgkjsfgks');
      expect(p.separatorWarningQueue, isEmpty);

      await settleImport(p);
    });

    await sub('25 pipe multi-parent -> one item per token (parity)', () async {
      final p = await loadAndStart(
          type: ImportEntityType.descriptors,
          csv: 'descriptors,parent\nfoo,rock||punk\n');

      expect(p.parentNotFoundQueue.map((e) => e.parentName), ['rock', 'punk']);
      expect(p.separatorWarningQueue, isEmpty);

      await settleImport(p);
    });

    // --- separator rectification for parent field ------------------------
    await sub('26 proceed clears the parent cell, keeps the name', () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres,
          csv: 'genres,parent\nfoo,"rock,|punk"\n');

      expect(p.separatorWarningIndex, 0);
      p.proceedSeparatorWarning();

      expect(p.importModifiedRows[0], ['foo', '']);
      expect(p.separatorWarningIndex, 1);
      expect(p.separatorWarningQueue.first.skipped, isFalse);

      await settleImport(p);
    });

    await sub('27 skip blanks the genre name column, keeps raw cell',
        () async {
      final p = await loadAndStart(
          type: ImportEntityType.genres,
          csv: 'genres,parent\nfoo,"rock,|punk"\n');

      p.skipSeparatorWarningTuple();

      expect(p.separatorWarningQueue.first.skipped, isTrue);
      expect(p.skippedTupleRowIndexes, contains(0));
      expect(p.importModifiedRows[0], ['', 'rock,|punk']);

      await settleImport(p);
    });

    await sub('28 skip blanks the descriptor name column (parity)', () async {
      final p = await loadAndStart(
          type: ImportEntityType.descriptors,
          csv: 'descriptors,parent\nfoo,"rock,|punk"\n');

      p.skipSeparatorWarningTuple();

      expect(p.separatorWarningQueue.first.skipped, isTrue);
      expect(p.skippedTupleRowIndexes, contains(0));
      expect(p.importModifiedRows[0], ['', 'rock,|punk']);

      await settleImport(p);
    });

    expect(ran, 28, reason: 'all 28 subcases must run');
  });
}