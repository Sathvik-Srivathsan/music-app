import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/utils/csv_utils.dart';

/// Regression tests for the fzy-based similarity used by the Type 1
/// recommendation dropdown (never auto-commits; dropdown ordering only).
void main() {
  group('fzy similarity regression', () {
    test('exact match scores 1.0', () {
      expect(
        CsvUtils.calculateSimilarity('merzbow', 'Merzbow'),
        closeTo(1.0, 0.0001),
      );
      expect(
        CsvUtils.calculateSimilarity('denzel curry', 'Denzel Curry'),
        closeTo(1.0, 0.0001),
      );
    });

    test('strong prefix beats scattered letters (merz vs smearz)', () {
      final merzbow = CsvUtils.calculateSimilarity('merz', 'Merzbow');
      final smearz = CsvUtils.calculateSimilarity('merz', 'Smearz');
      expect(merzbow, greaterThan(0.9));
      expect(smearz, greaterThan(0.0));
      expect(merzbow, greaterThan(smearz),
          reason: 'consecutive prefix must outrank scattered letters');
    });

    test('consecutive runs beat gappy matches within one target', () {
      final tight = CsvUtils.calculateSimilarity('file', 'file.txt');
      final gappy = CsvUtils.calculateSimilarity('felt', 'file.txt');
      expect(tight, greaterThan(gappy));
    });

    test('disjoint strings score zero', () {
      expect(CsvUtils.calculateSimilarity('abc', 'xyz'), 0.0);
      expect(CsvUtils.calculateSimilarity('', 'anything'), 0.0);
    });

    test('dropdown threshold sanity: real prefixes stay above 0.3', () {
      expect(
        CsvUtils.calculateSimilarity('abstr', 'Abstract Hip Hop'),
        greaterThan(0.3),
      );
      expect(
        CsvUtils.calculateSimilarity('jazz r', 'Jazz Rap'),
        greaterThan(0.3),
      );
      expect(
        CsvUtils.calculateSimilarity('experim', 'Experimental Hip Hop'),
        greaterThan(0.3),
      );
    });

    test('score never exceeds 1.0 even for longer queries', () {
      expect(
        CsvUtils.calculateSimilarity('merzbow extra tokens', 'Merzbow'),
        inInclusiveRange(0.0, 1.0),
      );
    });

    test('word-initial matches beat mid-word matches', () {
      final wordStart = CsvUtils.calculateSimilarity('hip', 'Hip Hop');
      final midWord =
          CsvUtils.calculateSimilarity('hip', 'Chip Shop');
      expect(wordStart, greaterThan(midWord));
    });
  });

  group('normalized fuzzy matching (hyphen / whitespace / zero-width)', () {
    test('spaces query matches hyphenated target', () {
      expect(
        CsvUtils.calculateSimilarity('neo psychedelia', 'Neo-Psychedelia'),
        closeTo(1.0, 0.0001),
      );
    });

    test('hyphen and case differences resolve to exact match', () {
      expect(
        CsvUtils.calculateSimilarity('neo-psychedelia', 'Neo Psychedelia'),
        closeTo(1.0, 0.0001),
      );
    });

    test('zero-width and nbsp characters are normalized away', () {
      const zw = '\u200B';
      const nbsp = '\u00A0';
      expect(
        CsvUtils.calculateSimilarity(
          'neo${zw}psychedelia',
          'Neo-Psychedelia',
        ),
        closeTo(1.0, 0.0001),
      );
      expect(
        CsvUtils.calculateSimilarity('neo$nbsp psychedelia', 'Neo-Psychedelia'),
        closeTo(1.0, 0.0001),
      );
    });

    test('unrelated genre stays well below match threshold', () {
      expect(
        CsvUtils.calculateSimilarity('neo psychedelia', 'Black Metal'),
        lessThan(0.3),
      );
    });

    test('partial query still ranks against normalized target', () {
      expect(
        CsvUtils.calculateSimilarity('neo psych', 'Neo-Psychedelia'),
        greaterThan(0.3),
      );
    });
  });
}
