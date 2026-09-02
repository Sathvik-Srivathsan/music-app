import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/utils/chip_text_logic.dart';

/// Series 2 — thorough probing of Type 2 matching edge cases.
void main() {
  const dbGenres = [
    'Abstract Hip Hop',
    'Conscious Hip Hop',
    'Jazz Rap',
    'Experimental Hip Hop',
    "G'n'R",
    'Café Del Mar',
  ];

  bool commits(String seg) => ChipTextLogic.matchType2(seg, dbGenres) != null;
  String? canon(String seg) => ChipTextLogic.matchType2(seg, dbGenres);

  group('Series 2 - separator robustness', () {
    test('comma without trailing space', () {
      final segs =
          ChipTextLogic.splitSegments('Jazz Rap,Experimental Hip Hop');
      expect(segs.length, 2);
      expect(commits(segs[0]), isTrue);
      expect(commits(segs[1]), isTrue);
    });

    test('double comma between segments', () {
      expect(
        ChipTextLogic.splitSegments('Jazz Rap,,Experimental Hip Hop').length,
        2,
      );
    });

    test('multiple commas collapse to nothing', () {
      expect(
        ChipTextLogic.splitSegments('Jazz Rap,,,,Experimental Hip Hop').length,
        2,
      );
    });

    test('trailing comma yields no phantom segment', () {
      expect(ChipTextLogic.splitSegments('Jazz Rap,'), ['Jazz Rap']);
    });

    test('leading comma yields no phantom segment', () {
      expect(ChipTextLogic.splitSegments(',Jazz Rap'), ['Jazz Rap']);
    });
  });

  group('Series 2 - whitespace robustness', () {
    test('extra spaces inside name', () {
      expect(commits('Jazz   Rap'), isTrue);
    });

    test('leading/trailing spaces around segment', () {
      expect(commits('   Jazz Rap   '), isTrue);
    });

    test('tab between words', () {
      expect(commits('Jazz\tRap'), isTrue);
    });

    test('newline between words', () {
      expect(commits('Abstract\nHip Hop'), isTrue);
    });

    test('non-breaking space (U+00A0) between words', () {
      expect(commits('Jazz\u00A0Rap'), isTrue);
    });

    test('ideographic space (U+3000) between words', () {
      expect(commits('Jazz\u3000Rap'), isTrue);
    });

    test('zero-width space (U+200B) spliced into name', () {
      expect(commits('Jazz\u200BRap'), isTrue);
    });

    test('zero-width non-joiner (U+200C) spliced into name', () {
      expect(commits('Jazz\u200CRap'), isTrue);
    });

    test('byte order mark (U+FEFF) prefix', () {
      expect(commits('\uFEFFJazz Rap'), isTrue);
    });
  });

  group('Series 2 - quote robustness', () {
    test('single-quote wrapped segment', () {
      expect(commits("'Jazz Rap'"), isTrue);
    });

    test('nested double+single wrapping', () {
      expect(commits("\"'Jazz Rap'\""), isTrue);
    });

    test('stray inner double quotes stripped symmetrically', () {
      expect(canon('Ja"zz Rap'), 'Jazz Rap');
      expect(commits('Ja"zz Ra"p'), isTrue);
    });

    test('wrapped apostrophe name survives outer-quote strip', () {
      expect(commits("G'n'R"), isTrue);
      expect(commits("'G'n'R'"), isTrue,
          reason: 'outer pair stripped once -> G\'n\'R -> exact match');
      expect(commits('"G\'n\'R"'), isTrue);
    });
  });

  group('Series 2 - case + accents', () {
    test('ALL CAPS input', () {
      expect(commits('JAZZ RAP'), isTrue);
      expect(commits('ABSTRACT HIP HOP'), isTrue);
    });

    test('mixed case input', () {
      expect(commits('JaZz rAp'), isTrue);
    });

    test('accented characters must match exactly (documented limit)', () {
      expect(commits('Cafe Del Mar'), isFalse,
          reason: 'no accent folding by design');
      expect(commits('CAFÉ DEL MAR'), isTrue);
      expect(commits('café del mar'), isTrue);
    });

    test('hyphens are normalized to spaces', () {
      expect(ChipTextLogic.matchType2('Abstract Hip-Hop', dbGenres),
          'Abstract Hip Hop');
      expect(ChipTextLogic.matchType2('abstract hip-hop', dbGenres),
          'Abstract Hip Hop');
      expect(ChipTextLogic.matchType2('abstract hip hop', dbGenres),
          'Abstract Hip Hop');
    });
  });

  group('Series 2 - junk segments', () {
    test('punctuation-only segment never commits', () {
      expect(canon('.'), isNull);
      expect(canon('-'), isNull);
    });

    test('fully-quoted empty string resolves to null', () {
      expect(ChipTextLogic.matchType2('""', dbGenres), isNull);
      expect(ChipTextLogic.matchType2("''", dbGenres), isNull);
    });

    test('whitespace-only segment resolves to null', () {
      expect(ChipTextLogic.matchType2('   ', dbGenres), isNull);
    });
  });

  group('Series 2 - scale sanity', () {
    test('100-segment paste still resolves its tail', () {
      final long = List.generate(
          100, (i) => i == 99 ? 'Experimental Hip Hop' : 'Genre Fill $i');
      final segs = ChipTextLogic.splitSegments(long.join(', '));
      expect(segs.length, 100);
      expect(commits(segs[99]), isTrue);
    });

    test('duplicate within one paste resolves identically both times', () {
      final a = canon('Conscious Hip Hop');
      final b = canon('conscious   hip hop');
      expect(a, b);
      expect(a, 'Conscious Hip Hop');
    });
  });
}
