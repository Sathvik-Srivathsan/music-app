import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/features/search/domain/record_collation.dart';
import 'package:music_collection/features/search/domain/search_query.dart';
import 'package:music_collection/features/search/domain/taxonomy_closure.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';

RecordDetails _rec({
  int id = 1,
  String name = 'Blue Train',
  String? type = 'Album',
  String? release = '1958-01-01',
  String? added,
  String? comments,
  bool status = false,
  List<Artist> artists = const [],
  List<Genre> genres = const [],
  List<Descriptor> descriptors = const [],
  List<StreamingService> streaming = const [],
}) {
  return RecordDetails(
    record: Record(
      recordId: id,
      recordName: name,
      recordType: type,
      releaseDate: release,
      dateAdded: added ?? '05/07/2026',
      comments: comments,
      status: status,
    ),
    artists: List.of(artists),
    genres: List.of(genres),
    descriptors: List.of(descriptors),
    streaming: List.of(streaming),
  );
}

void main() {
  group('StreamingService.fromJson legacy tolerance', () {
    test('SQL NULL url/name degrade to empty strings', () {
      final s = StreamingService.fromJson({
        'record_id': 9,
        'service_name': 'Youtube',
        'service_url': null,
      });
      expect(s.serviceName, 'Youtube');
      expect(s.serviceUrl, '');
    });

    test('fully NULL row parses without throwing', () {
      final s = StreamingService.fromJson({
        'record_id': null,
        'service_name': null,
        'service_url': null,
      });
      expect(s.recordId, isNull);
      expect(s.serviceName, '');
      expect(s.serviceUrl, '');
    });
  });

  group('parseFlexibleDate', () {
    test('accepts ISO partials', () {
      expect(parseFlexibleDate('2026'), '2026');
      expect(parseFlexibleDate('2026-07'), '2026-07');
      expect(parseFlexibleDate('2026-07-05'), '2026-07-05');
    });

    test('accepts slash separators everywhere', () {
      expect(parseFlexibleDate('2026/07/05'), '2026-07-05');
      expect(parseFlexibleDate('2026/07'), '2026-07');
      expect(parseFlexibleDate('07/2026'), '2026-07');
      expect(parseFlexibleDate('05/07/2026'), '2026-07-05');
    });

    test('day-first three-part dates', () {
      expect(parseFlexibleDate('05-07-2026'), '2026-07-05');
      expect(parseFlexibleDate('31-01-1999'), '1999-01-31');
    });

    test('month-year two-part dates', () {
      expect(parseFlexibleDate('7-2026'), '2026-07');
      expect(parseFlexibleDate('12-2026'), '2026-12');
    });

    test('rejects junk, out-of-range and ambiguous shapes', () {
      expect(parseFlexibleDate(''), isNull);
      expect(parseFlexibleDate(null), isNull);
      expect(parseFlexibleDate('March 2020'), isNull);
      expect(parseFlexibleDate('13-2026'), isNull); // month 13
      expect(parseFlexibleDate('32-01-2020'), isNull); // day 32
      expect(parseFlexibleDate('2026-13'), isNull);
      expect(parseFlexibleDate('2026-07-05-09'), isNull);
      expect(parseFlexibleDate('26-07'), isNull); // neither shape
    });
  });

  group('parseFlexibleDate missing-leading-zero tolerance', () {
    test('accepts 1-2 digit day and month components', () {
      expect(parseFlexibleDate('2-9-2026'), '2026-09-02');
      expect(parseFlexibleDate('2-09-2026'), '2026-09-02');
      expect(parseFlexibleDate('02-9-2026'), '2026-09-02');
      expect(parseFlexibleDate('2026-9-2'), '2026-09-02');
      expect(parseFlexibleDate('2026-09-2'), '2026-09-02');
      expect(parseFlexibleDate('2026-9-02'), '2026-09-02');
      expect(parseFlexibleDate('9-2026'), '2026-09');
      expect(parseFlexibleDate('2026-9'), '2026-09');
    });
  });

  group('canonicalizeReleaseDate + mask', () {
    test('full date (day-first, missing zeros) -> ISO + mask 7', () {
      expect(canonicalizeReleaseDate('2-9-2026'),
          (iso: '2026-09-02', mask: 7));
      expect(canonicalizeReleaseDate('05/07/2026'),
          (iso: '2026-07-05', mask: 7));
    });

    test('year-first three part -> ISO + mask 7', () {
      expect(canonicalizeReleaseDate('2026-9-2'),
          (iso: '2026-09-02', mask: 7));
    });

    test('year-month -> ISO day 01 + mask 3', () {
      expect(canonicalizeReleaseDate('09-2026'),
          (iso: '2026-09-01', mask: 3));
      expect(canonicalizeReleaseDate('2026-09'),
          (iso: '2026-09-01', mask: 3));
      expect(canonicalizeReleaseDate('9-2026'),
          (iso: '2026-09-01', mask: 3));
    });

    test('year only -> ISO Jan 1 + mask 1', () {
      expect(canonicalizeReleaseDate('2010'), (iso: '2010-01-01', mask: 1));
    });

    test('empty / invalid -> null iso + mask 0', () {
      expect(canonicalizeReleaseDate(''), (iso: null, mask: 0));
      expect(canonicalizeReleaseDate(null), (iso: null, mask: 0));
      expect(canonicalizeReleaseDate('March 2020'), (iso: null, mask: 0));
      expect(canonicalizeReleaseDate('13-2026'), (iso: null, mask: 0));
    });

    test('rejects impossible real-world dates', () {
      expect(canonicalizeReleaseDate('2026-02-30'), (iso: null, mask: 0));
      expect(canonicalizeReleaseDate('30-02-2026'), (iso: null, mask: 0));
      expect(canonicalizeReleaseDate('2026-13-01'), (iso: null, mask: 0));
    });

    test('only valid masks are emitted (validity invariant)', () {
      expect(canonicalizeReleaseDate('2010').mask, 1);
      expect(canonicalizeReleaseDate('2010-05').mask, 3);
      expect(canonicalizeReleaseDate('05-2010').mask, 3);
      expect(canonicalizeReleaseDate('10-05-2010').mask, 7);
      expect(canonicalizeReleaseDate('2010-05-10').mask, 7);
    });
  });

  group('formatDisplayDate (granularity-preserving DD-MM-YYYY)', () {
    test('mask 1 -> year only', () {
      expect(formatDisplayDate('2010-01-01', 1), '2010');
    });
    test('mask 3 -> month-year', () {
      expect(formatDisplayDate('2026-09-01', 3), '09-2026');
    });
    test('mask 7 -> full day-month-year', () {
      expect(formatDisplayDate('2026-09-02', 7), '02-09-2026');
    });
    test('empty / unknown -> null', () {
      expect(formatDisplayDate('2026-09-02', 0), isNull);
      expect(formatDisplayDate('2026-09-02', 2), isNull);
      expect(formatDisplayDate(null, 7), isNull);
    });
  });

  group('dateMatches operators', () {
    test('exact matches full normalized string', () {
      expect(
          dateMatches(
              recordValue: '1965-04-21',
              operator: DateOperator.exactDate,
              queryValue1: '21/04/1965'),
          isTrue);
      expect(
          dateMatches(
              recordValue: '1965-04-21',
              operator: DateOperator.exactDate,
              queryValue1: '1965-04'),
          isFalse);
    });

    test('year-only records behave as full-year windows', () {
      expect(dateMatches(recordValue: '1975', operator: DateOperator.onOrBefore, queryValue1: '1975-06'), isTrue);
      expect(dateMatches(recordValue: '1975', operator: DateOperator.onOrBefore, queryValue1: '1974-12-31'), isFalse);
      expect(dateMatches(recordValue: '1975', operator: DateOperator.onOrAfter, queryValue1: '1975-06-15'), isTrue);
      expect(dateMatches(recordValue: '1975', operator: DateOperator.onOrAfter, queryValue1: '1976-01-01'), isFalse);
    });

    test('between inclusive/exclusive boundaries', () {
      expect(dateMatches(recordValue: '1984-06', operator: DateOperator.betweenInclusive, queryValue1: '1984-01', queryValue2: '1984-12'), isTrue);
      expect(dateMatches(recordValue: '1983', operator: DateOperator.betweenInclusive, queryValue1: '1984-01', queryValue2: '1984-12'), isFalse);
      expect(dateMatches(recordValue: '1984', operator: DateOperator.betweenExclusive, queryValue1: '1984-01-01', queryValue2: '1984-12-31'), isFalse);
      expect(dateMatches(recordValue: '1984-05-05', operator: DateOperator.betweenExclusive, queryValue1: '1984-01-01', queryValue2: '1984-12-31'), isTrue);
    });

    test('dd/MM/yyyy added-stamps are queryable in any format', () {
      expect(dateMatches(recordValue: '05/07/2026', operator: DateOperator.onOrAfter, queryValue1: '07-2026'), isTrue);
      expect(dateMatches(recordValue: '05/07/2026', operator: DateOperator.onOrAfter, queryValue1: '2026-07-06'), isFalse);
      expect(dateMatches(recordValue: '05/07/2026', operator: DateOperator.onOrBefore, queryValue1: '08/2026'), isTrue);
    });

    test('missing record dates never match', () {
      expect(dateMatches(recordValue: null, operator: DateOperator.onOrAfter, queryValue1: '2000'), isFalse);
      expect(dateMatches(recordValue: '', operator: DateOperator.onOrBefore, queryValue1: '2000'), isFalse);
    });
  });

  group('SearchQueryEngine.matches', () {
    test('empty query matches everything (browse-all)', () {
      final q = SearchQueryParams();
      expect(SearchQueryEngine.matches(_rec(), q), isTrue);
      expect(SearchQueryEngine.matches(_rec(status: true), q), isTrue);
    });

    test('name substring match is case-insensitive', () {
      final q = SearchQueryParams()..nameText = 'blue train';
      expect(SearchQueryEngine.matches(_rec(name: 'Blue Train'), q), isTrue);
      final q2 = SearchQueryParams()..nameText = 'zzz';
      expect(SearchQueryEngine.matches(_rec(), q2), isFalse);
    });

    test('fuzzy name match above threshold passes via similarity fn', () {
      final q = SearchQueryParams()..nameText = 'Blue Trane';
      expect(
        SearchQueryEngine.matches(
          _rec(name: 'Blue Train'),
          q,
          similarity: (query, target) => 0.9,
        ),
        isTrue,
      );
      expect(
        SearchQueryEngine.matches(
          _rec(name: 'Blue Train'),
          q,
          similarity: (query, target) => 0.2,
        ),
        isFalse,
      );
    });

    test('artists require ANY overlap (AND across categories)', () {
      final a1 = Artist(artistId: 10, artistName: 'Coltrane');
      final a2 = Artist(artistId: 20, artistName: 'Miles');
      final r = _rec(artists: [a1]);

      final qBoth = SearchQueryParams()
        ..artistIds.addAll([a1.artistId!, a2.artistId!]);
      expect(SearchQueryEngine.matches(r, qBoth), isTrue);

      final qOther = SearchQueryParams()..artistIds.add(20);
      expect(SearchQueryEngine.matches(r, qOther), isFalse);
    });

    test('genres ANY vs ALL switch', () {
      final g1 = Genre(genreId: 30, genreName: 'Hard Bop');
      final g2 = Genre(genreId: 31, genreName: 'Jazz');
      final r = _rec(genres: [g1]);

      final anyQ = SearchQueryParams()
        ..genreIds.addAll([30, 31])
        ..genresMode = StreamingFilterMode.any;
      expect(SearchQueryEngine.matches(r, anyQ), isTrue);

      final allQ = SearchQueryParams()
        ..genreIds.addAll([30, 31])
        ..genresMode = StreamingFilterMode.all;
      expect(SearchQueryEngine.matches(r, allQ), isFalse);

      final allOk = SearchQueryParams()
        ..genreIds.add(30)
        ..genresMode = StreamingFilterMode.all;
      expect(SearchQueryEngine.matches(_rec(genres: [g1, g2]), allOk), isTrue);
    });

    test('descriptors ANY vs ALL switch', () {
      final d1 = Descriptor(descriptorId: 40, descriptorName: 'warm');
      final d2 = Descriptor(descriptorId: 41, descriptorName: 'rhythmic');
      final r = _rec(descriptors: [d1]);

      final anyQ = SearchQueryParams()
        ..descriptorIds.addAll([d1.descriptorId!, d2.descriptorId!])
        ..descriptorsMode = StreamingFilterMode.any;
      expect(SearchQueryEngine.matches(r, anyQ), isTrue);

      final allQ = SearchQueryParams()
        ..descriptorIds.addAll([d1.descriptorId!, d2.descriptorId!])
        ..descriptorsMode = StreamingFilterMode.all;
      expect(SearchQueryEngine.matches(r, allQ), isFalse);
    });

    test('record types: ANY across selected, none selected = all', () {
      final noneQ = SearchQueryParams();
      expect(SearchQueryEngine.matches(_rec(type: 'EP'), noneQ), isTrue);

      final q = SearchQueryParams()
        ..recordTypes.addAll(['EP', 'Single']);
      expect(SearchQueryEngine.matches(_rec(type: 'EP'), q), isTrue);
      expect(SearchQueryEngine.matches(_rec(type: 'Single'), q), isTrue);
      expect(SearchQueryEngine.matches(_rec(type: 'Album'), q), isFalse);
      expect(SearchQueryEngine.matches(_rec(type: null), q), isFalse);
    });

    test('streaming OR vs ALL modes use display names', () {
      final ssqtDisplay = 'SoulSeekQT (SSQT)';
      final r = _rec(streaming: [
        StreamingService(serviceName: 'Spotify', serviceUrl: ''),
        StreamingService(serviceName: 'SoulSeekQT', serviceUrl: ''),
      ]);
      final orQ = SearchQueryParams()
        ..streamingServices.addAll(['Bandcamp', 'Spotify'])
        ..streamingMode = StreamingFilterMode.any;
      expect(SearchQueryEngine.matches(r, orQ), isTrue);

      final allQ = SearchQueryParams()
        ..streamingServices.addAll(['Bandcamp', 'Spotify'])
        ..streamingMode = StreamingFilterMode.all;
      expect(SearchQueryEngine.matches(r, allQ), isFalse);

      final allOk = SearchQueryParams()
        ..streamingServices.addAll(['Spotify', ssqtDisplay])
        ..streamingMode = StreamingFilterMode.all;
      expect(SearchQueryEngine.matches(r, allOk), isTrue);
    });

    test('release-date operator filters records', () {
      final q = SearchQueryParams()
        ..releaseOperator = DateOperator.onOrAfter
        ..releaseValue1 = '1960-01-01';
      expect(
          SearchQueryEngine.matches(_rec(release: '1965-04-21'), q),
          isTrue);
      expect(
          SearchQueryEngine.matches(_rec(release: '1958-09'), q),
          isFalse);
    });
  });

  group('previewLines (Option A)', () {
    test('empty query announces browse-all', () {
      final lines = SearchQueryEngine.previewLines(SearchQueryParams());
      expect(lines.single.value, contains('ALL'));
    });

    test('only filled parameters appear with mode labels', () {
      final q = SearchQueryParams()
        ..nameText = 'kind of blue'
        ..recordTypes.add('Album')
        ..genreIds.addAll([30, 31])
        ..genresMode = StreamingFilterMode.all
        ..streamingServices.add('Spotify');
      final lines = SearchQueryEngine.previewLines(q);
      expect(lines.map((e) => e.key).toList(),
          ['Record Name', 'Genres', 'Record Types', 'Streaming']);
      expect(lines[1].value, contains('ALL'));
      expect(lines[2].value, contains('ANY'));
      expect(lines[3].value, contains('ANY'));
    });

    test('per-type resolvers show entity names instead of counts', () {
      final q = SearchQueryParams()
        ..artistIds.addAll([10, 11])
        ..genreIds.addAll([30, 31])
        ..descriptorIds.addAll({40});
      final artistNames = {
        10: 'Coltrane',
        11: 'Miles Davis',
      };
      final genreNames = {
        30: 'Hard Bop',
        31: 'Jazz',
      };
      final descriptorNames = {
        40: 'warm',
      };
      final lines = SearchQueryEngine.previewLines(
        q,
        artistNames: artistNames,
        genreNames: genreNames,
        descriptorNames: descriptorNames,
      );
      expect(lines[0].value, contains('Coltrane'));
      expect(lines[0].value, contains('Miles Davis'));
      expect(lines[1].value, contains('Hard Bop'));
      expect(lines[1].value, contains('Jazz'));
      expect(lines[2].value, contains('warm'));
    });

    test('per-type resolvers never collide across entity categories', () {
      // Regression: artists, genres and descriptors each have their own ID
      // space, so numeric id 5 may be BOTH artist "Run the Jewels" AND
      // descriptor "suspenseful". A single flat resolver silently let the
      // latter overwrite the former (bug), so the Artists preview line showed
      // "suspenseful". Passing per-type maps keeps each category independent.
      final q = SearchQueryParams()
        ..artistIds.addAll({5})
        ..descriptorIds.addAll({5});
      final lines = SearchQueryEngine.previewLines(
        q,
        artistNames: {5: 'Run the Jewels'},
        descriptorNames: {5: 'suspenseful'},
      );
      expect(lines[0].value, contains('Run the Jewels'));
      expect(lines[0].value, isNot(contains('suspenseful')));
      expect(lines[1].value, contains('suspenseful'));
    });

    test('per-type resolver truncates at 5 names with ...and N more', () {
      final q = SearchQueryParams()
        ..artistIds.addAll({1, 2, 3, 4, 5, 6, 7});
      final artistNames = {
        1: 'A', 2: 'B', 3: 'C', 4: 'D', 5: 'E', 6: 'F', 7: 'G',
      };
      final lines =
          SearchQueryEngine.previewLines(q, artistNames: artistNames);
      expect(lines[0].value, contains('...and 2 more'));
      expect(lines[0].value, contains('A, B, C, D, E'));
    });

    test('fallback to count when no resolver is given', () {
      final q = SearchQueryParams()
        ..artistIds.addAll([10, 11]);
      final lines = SearchQueryEngine.previewLines(q);
      expect(lines[0].value, contains('2 selected'));
    });

    test('between shows both bounds', () {
      final q = SearchQueryParams()
        ..addedOperator = DateOperator.betweenInclusive
        ..addedValue1 = '01-2026'
        ..addedValue2 = '2026-08';
      final line = SearchQueryEngine.previewLines(q).single;
      expect(line.value, contains('2026-01'));
      expect(line.value, contains('2026-08'));
    });

    test('comments filter appears in preview', () {
      final q = SearchQueryParams()..commentsText = 'gatefold';
      final line = SearchQueryEngine.previewLines(q).single;
      expect(line.key, 'Comments');
      expect(line.value, contains('gatefold'));
    });
  });

  group('comments filter (fuzzy type-2 only)', () {
    test('empty comments query matches everything', () {
      final q = SearchQueryParams();
      expect(SearchQueryEngine.matches(_rec(comments: null), q), isTrue);
      expect(SearchQueryEngine.matches(_rec(comments: 'anything'), q), isTrue);
    });

    test('similarity above threshold passes, below fails', () {
      final q = SearchQueryParams()..commentsText = 'ring wear';
      expect(
        SearchQueryEngine.matches(
          _rec(comments: 'slight ring wear on sleeve'),
          q,
          similarity: (query, target) => 0.8,
        ),
        isTrue,
      );
      expect(
        SearchQueryEngine.matches(
          _rec(comments: 'totally unrelated'),
          q,
          similarity: (query, target) => 0.1,
        ),
        isFalse,
      );
    });

    test('no substring shortcut - identical text still needs similarity',
        () {
      final q = SearchQueryParams()..commentsText = 'gatefold';
      // Even an exact substring match fails when the similarity fn
      // reports below threshold.
      expect(
        SearchQueryEngine.matches(
          _rec(comments: 'has gatefold sleeve'),
          q,
          similarity: (query, target) => 0.05,
        ),
        isFalse,
      );
      expect(
        SearchQueryEngine.matches(
          _rec(comments: null),
          q,
          // Real similarity of anything against an empty target is
          // ~0; the stub honours that instead of returning a
          // constant.
          similarity: (query, target) => target.isEmpty ? 0.0 : 0.9,
        ),
        isFalse,
      );
    });
  });

  group('record collation', () {
    void expectOrdered(List<String> names) {
      for (var i = 0; i < names.length - 1; i++) {
        expect(compareRecordNames(names[i], names[i + 1]) < 0,
            isTrue,
            reason: '"${names[i]}" should sort before "${names[i + 1]}"');
        expect(compareRecordNames(names[i + 1], names[i]) > 0, isTrue,
            reason: 'antisymmetry broken at ${names[i]}');
      }
    }

    test('digits before letters', () {
      expectOrdered(['10 Songs', 'Abbey Road']);
      expectOrdered(['2 Legit', 'Zappa']);
    });

    test('uppercase block precedes lowercase block entirely', () {
      expectOrdered(['Zebra', 'apple']);
      expectOrdered(['Éclair'.toUpperCase(), 'banana']);
    });

    test('base letter before its diacritic variants (e before é)', () {
      expectOrdered(['Eagle', 'Éclair']);
      expectOrdered(['Nadia', 'Ñandú']);
    });

    test('variants stay within their letter group', () {
      expectOrdered(['Abba', 'Ábaco', 'Bat']);
    });

    test('case never intermixes within a letter', () {
      expectOrdered(['Apple', 'apple']);
      expectOrdered(['Ábaco', 'ábaco']);
    });

    test('CJK and symbols sort after all Latin', () {
      expectOrdered(['ZZ Top', '中文名']);
      expectOrdered(['Miles Davis', '♪ collection']);
    });

    test('prefix sorts first', () {
      expect(compareRecordNames('Kind', 'Kind of Blue') < 0, isTrue);
      expect(compareRecordNames('Kind', 'Kind'), 0);
    });
  });

  group('taxonomy closure', () {
    final edges = [
      const MapEntry(81, 677),
      const MapEntry(677, 286),
      const MapEntry(677, 2148),
    ];
    late Map<int, Set<int>> idx;

    setUp(() => idx = buildChildrenIndex(edges));

    test('index maps parent to children', () {
      expect(idx[81], {677});
      expect(idx[677], {286, 2148});
      expect(idx[999], isNull);
    });

    test('closure is transitive and includes self', () {
      expect(closureOf(81, idx), {81, 677, 286, 2148});
      expect(closureOf(677, idx), {677, 286, 2148});
      expect(closureOf(286, idx), {286});
    });

    test('cycle-safe', () {
      final cyclic = buildChildrenIndex([
        ...edges,
        const MapEntry(286, 81), // would loop forever if naive
      ]);
      expect(closureOf(81, cyclic), {81, 677, 286, 2148});
    });

    test('unionClosures merges branches', () {
      expect(
        unionClosures([81, 5], {
          ...idx,
          5: <int>{7},
        }),
        {81, 677, 286, 2148, 5, 7},
      );
    });
  });

  group('hierarchy-aware matching', () {
    final idx = fullClosures([
      const MapEntry(81, 677),
      const MapEntry(677, 286),
    ]);

    test('ANY mode: selecting a parent surfaces child-genre records', () {
      final r = _rec(genres: [Genre(genreId: 286, genreName: 'Child')]);
      final q = SearchQueryParams()..genreIds.add(81);

      // Without hierarchy data: no direct id overlap -> miss.
      expect(SearchQueryEngine.matches(r, q), isFalse);
      // With closure: parent's descendants match.
      expect(SearchQueryEngine.matches(r, q, genreClosure: idx), isTrue);
    });

    test('ANY mode tolerates unhit extras when one selection matches', () {
      final r = _rec(genres: [Genre(genreId: 81, genreName: 'Parent')]);
      final qHit = SearchQueryParams()
        ..genreIds.addAll([81, 677])
        ..genresMode = StreamingFilterMode.any;
      expect(SearchQueryEngine.matches(r, qHit, genreClosure: idx), isTrue);

      final qMiss = SearchQueryParams()
        ..genreIds.addAll([900, 901])
        ..genresMode = StreamingFilterMode.any;
      expect(SearchQueryEngine.matches(r, qMiss, genreClosure: idx),
          isFalse);
    });

    test('ALL mode requires every selected id covered (own or descendant)',
        () {
      final r = _rec(genres: [
        Genre(genreId: 677, genreName: 'Mid'),
      ]);
      final qCovered = SearchQueryParams()
        ..genreIds.add(81) // 677 ∈ closure(81)
        ..genresMode = StreamingFilterMode.all;
      expect(
          SearchQueryEngine.matches(r, qCovered, genreClosure: idx), isTrue);

      final qUncovered = SearchQueryParams()
        ..genreIds.addAll([81, 900])
        ..genresMode = StreamingFilterMode.all;
      expect(
          SearchQueryEngine.matches(r, qUncovered, genreClosure: idx),
          isFalse);
    });

    test('descriptors use their own closure map', () {
      final didx = fullClosures([const MapEntry(40, 54)]);
      final r = _rec(
          descriptors: [Descriptor(descriptorId: 54, descriptorName: 'D')]);
      final q = SearchQueryParams()..descriptorIds.add(40);
      expect(SearchQueryEngine.matches(r, q, descriptorClosure: didx),
          isTrue);
      expect(SearchQueryEngine.matches(r, q), isFalse);
    });
  });

  group('groupKeysFor (individual grouping)', () {
    test('multi-value fields yield one key per value', () {
      final r = _rec(
        genres: [
          Genre(genreId: 1, genreName: 'Jazz'),
          Genre(genreId: 2, genreName: 'Fusion'),
        ],
        artists: [Artist(artistId: 9, artistName: 'Miles')],
      );
      expect(SearchQueryEngine.groupKeysFor(r, 'genres'),
          ['Jazz', 'Fusion']);
      expect(SearchQueryEngine.groupKeysFor(r, 'artists'), ['Miles']);
    });

    test('empty multi-value fields collapse into (none)', () {
      final r = _rec();
      expect(SearchQueryEngine.groupKeysFor(r, 'genres'), ['(none)']);
      expect(SearchQueryEngine.groupKeysFor(r, 'descriptors'), ['(none)']);
    });

    test('scalar fields stay single-keyed', () {
      final r = _rec(type: 'Album', release: '1965');
      expect(SearchQueryEngine.groupKeysFor(r, 'type'), ['Album']);
      expect(SearchQueryEngine.groupKeysFor(r, 'releaseDate'), ['1965']);
      expect(SearchQueryEngine.groupKeysFor(r, 'unknownfield'), ['']);
    });
  });
}
