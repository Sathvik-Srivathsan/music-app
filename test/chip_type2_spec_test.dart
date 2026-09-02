import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/utils/chip_text_logic.dart';

/// Series 1 — deterministic spec contract for the paste pipeline.
///
/// Contract: parse input by comma into substrings; each substring goes
/// through Type 2 matching (exact, ignoring case/whitespace/quote noise).
/// Match => add chip. No match => create-new popup. Fuzzy similarity is
/// Type 1 (recommendation dropdown) only and NEVER auto-commits.
void main() {
  const dbGenres = [
    'Abstract Hip Hop',
    'Conscious Hip Hop',
    'Jazz Rap',
    'Experimental Hip Hop',
  ];

  const userPaste = 'Abstract Hip Hop, Conscious Hip Hop, Jazz Rap, '
      'Conscious Hip Hop, Experimental Hip Hop';

  group('Series 1 - paste pipeline spec contract', () {
    final segments = ChipTextLogic.splitSegments(userPaste);

    test('CSV line parses into exactly 5 substrings in order', () {
      expect(segments, [
        'Abstract Hip Hop',
        'Conscious Hip Hop',
        'Jazz Rap',
        'Conscious Hip Hop',
        'Experimental Hip Hop',
      ]);
    });

    test('every substring resolves Type 2 -> chip, zero popups', () {
      for (final segment in segments) {
        expect(
          ChipTextLogic.matchType2(segment, dbGenres),
          isIn(dbGenres),
          reason: '"$segment" must resolve to an existing genre',
        );
      }
    });

    test('duplicate substring resolves to same canonical genre', () {
      final first = ChipTextLogic.matchType2(segments[1], dbGenres);
      final dup = ChipTextLogic.matchType2(segments[3], dbGenres);
      expect(first, 'Conscious Hip Hop');
      expect(dup, first);
    });

    test('case-insensitive exact name commits as chip', () {
      expect(ChipTextLogic.matchType2('merzbow', ['Merzbow']), 'Merzbow');
      expect(ChipTextLogic.matchType2('MERZBOW', ['Merzbow']), 'Merzbow');
      expect(
        ChipTextLogic.matchType2('MeRzBoW', ['Merzbow']),
        'Merzbow',
      );
    });

    test('fuzzy-only partial name does NOT commit (popup expected)', () {
      expect(ChipTextLogic.matchType2('merzbo', ['Merzbow']), isNull);
      expect(ChipTextLogic.matchType2('abstract hip', dbGenres), isNull);
      expect(ChipTextLogic.matchType2('hip hop', dbGenres), isNull);
    });

    test('quoted CSV export round-trips to chips', () {
      const quoted = '"Abstract Hip Hop","Conscious Hip Hop","Jazz Rap"';
      final decisions = ChipTextLogic.splitSegments(quoted)
          .map((s) => ChipTextLogic.matchType2(s, dbGenres))
          .toList();
      expect(decisions, everyElement(isNotNull));
      expect(decisions[0], 'Abstract Hip Hop');
      expect(decisions[2], 'Jazz Rap');
    });
  });
}
