import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';

final _ids = <String, int>{};
int _cid = 0;
int _lookup(String name) => _ids.putIfAbsent(name, () => ++_cid);

RecordDetails _row({
  required int id,
  required String name,
  bool finished = false,
  String? type = 'Album',
  String? releaseDate = '1965-04-21',
  List<String> artists = const ['Artist'],
  List<String> genres = const ['Jazz'],
  List<String> descriptors = const ['Classic'],
  List<String> streaming = const ['Spotify'],
}) {
  return RecordDetails(
    record: Record(
      recordId: id,
      recordName: name,
      recordType: type,
      releaseDate: releaseDate,
      dateAdded: '05/07/2026',
      status: finished,
    ),
    artists: [
      for (final a in artists) Artist(artistId: _lookup(a), artistName: a),
    ],
    genres: [
      for (final g in genres) Genre(genreId: _lookup(g), genreName: g),
    ],
    descriptors: [
      for (final d in descriptors)
        Descriptor(descriptorId: _lookup(d), descriptorName: d),
    ],
    streaming: [
      for (final (i, s) in streaming.indexed)
        StreamingService(recordId: id, serviceName: s, serviceUrl: 'url$i'),
    ],
  );
}

void main() {
  group('StatisticsEngine.yearOf / decadeOf', () {
    test('parses full date', () {
      expect(StatisticsEngine.yearOf(_row(id: 1, name: 'A', releaseDate: '1965-04-21')), 1965);
    });

    test('parses year-only', () {
      expect(StatisticsEngine.yearOf(_row(id: 1, name: 'A', releaseDate: '1973')), 1973);
    });

    test('null for empty/unparseable', () {
      expect(StatisticsEngine.yearOf(_row(id: 1, name: 'A', releaseDate: '')), isNull);
      expect(StatisticsEngine.yearOf(_row(id: 1, name: 'A', releaseDate: null)), isNull);
      expect(StatisticsEngine.yearOf(_row(id: 1, name: 'A', releaseDate: 'nonsense')), isNull);
    });

    test('decade floors to tens', () {
      expect(StatisticsEngine.decadeOf(_row(id: 1, name: 'A', releaseDate: '1965-04-21')), 1960);
      expect(StatisticsEngine.decadeOf(_row(id: 1, name: 'A', releaseDate: '2001')), 2000);
    });
  });

  group('StatisticsEngine.decadeData', () {
    test('buckets ascending and keeps Unknown last', () {
      final rows = [
        _row(id: 1, name: 'A', releaseDate: '1965-01-01'),
        _row(id: 2, name: 'B', releaseDate: '1967-01-01'),
        _row(id: 3, name: 'C', releaseDate: '1980-01-01'),
        _row(id: 4, name: 'D', releaseDate: ''),
      ];
      final data = StatisticsEngine.decadeData(rows);
      expect(data.unknownCount, 1);
      final labels = data.buckets.map((b) => b.label).toList();
      expect(labels, ['1960s', '1980s', 'Unknown']);
      expect(data.buckets[0].value, 2);
      expect(data.buckets[1].value, 1);
      expect(data.buckets[2].value, 1);
    });

    test('all-unknown produces only Unknown bucket', () {
      final data = StatisticsEngine.decadeData([
        _row(id: 1, name: 'A', releaseDate: ''),
        _row(id: 2, name: 'B', releaseDate: null),
      ]);
      expect(data.buckets, [const StatBar('Unknown', 2)]);
      expect(data.unknownCount, 2);
    });

    test('empty list yields no buckets', () {
      expect(StatisticsEngine.decadeData([]).buckets, isEmpty);
    });
  });

  group('StatisticsEngine.computeOverview', () {
    test('counts statuses and distinct entities', () {
      final rows = [
        _row(id: 1, name: 'A', artists: ['X'], genres: ['Jazz', 'Blues'],
            descriptors: ['C'], releaseDate: '1965'),
        _row(id: 2, name: 'B', finished: true, artists: ['X', 'Y'],
            genres: ['Jazz'], descriptors: ['C', 'D'], streaming: []),
        _row(id: 3, name: 'C', artists: ['X'], genres: ['Jazz'],
            descriptors: ['C'], releaseDate: ''),
      ];
      final o = StatisticsEngine.computeOverview(rows);
      expect(o.totalRecords, 3);
      expect(o.activeRecords, 2);
      expect(o.finishedRecords, 1);
      expect(o.totalArtists, 2); // X, Y distinct
      expect(o.totalGenres, 2); // Jazz, Blues
      expect(o.totalDescriptors, 2); // C, D
      expect(o.recordsWithStreaming, 2);
      expect(o.totalStreamingLinks, 2);
      expect(o.recordsWithUnknownYear, 1);
    });
  });

  group('StatisticsEngine.statusSlices', () {
    test('always two slices', () {
      final slices = StatisticsEngine.statusSlices([
        _row(id: 1, name: 'A'),
        _row(id: 2, name: 'B', finished: true),
      ]);
      expect(slices.length, 2);
      expect(slices[0].label, 'Active');
      expect(slices[0].value, 1);
      expect(slices[1].label, 'Finished');
      expect(slices[1].value, 1);
    });
  });

  group('StatisticsEngine.topEntities', () {
    test('top artists sorted desc with distinct count', () {
      final rows = [
        _row(id: 1, name: 'A', artists: ['X', 'Y']),
        _row(id: 2, name: 'B', artists: ['X']),
        _row(id: 3, name: 'C', artists: ['Z']),
      ];
      final artists = StatisticsEngine.topArtists(rows, top: 5);
      expect(artists.first.name, 'X');
      expect(artists.first.count, 2);
      expect(artists.length, 3);
    });

    test('top respects cap', () {
      final rows = [
        for (var i = 0; i < 15; i++)
          _row(id: i + 1, name: 'R$i', artists: ['Art$i']),
      ];
      expect(StatisticsEngine.topArtists(rows, top: 5).length, 5);
    });
  });

  group('StatisticsEngine.recordTypeBars', () {
    test('counts by type desc', () {
      final bars = StatisticsEngine.recordTypeBars([
        _row(id: 1, name: 'A', type: 'Album'),
        _row(id: 2, name: 'B', type: 'Album'),
        _row(id: 3, name: 'C', type: 'EP'),
      ]);
      expect(bars.first.label, 'Album');
      expect(bars.first.value, 2);
    });
  });

  group('StatisticsEngine.streamingPie', () {
    test('maps empty service to No service listed', () {
      final pie = StatisticsEngine.streamingPie([
        _row(id: 1, name: 'A', streaming: <String>[]),
      ]);
      expect(pie.slices.length, 1);
      expect(pie.slices.first.label, 'No service listed');
      expect(pie.slices.first.value, 1);
    });

    test('collapses tail to Other beyond 6 slices', () {
      final rows = [
        for (var i = 0; i < 8; i++)
          _row(id: i + 1, name: 'R$i', streaming: ['Service$i']),
      ];
      final pie = StatisticsEngine.streamingPie(rows);
      expect(pie.slices.length, StatisticsEngine.maxPieSlices);
      expect(pie.slices.last.label, 'Other');
      expect(pie.hadOther, isTrue);
    });

    test('under cap keeps all slices, no Other', () {
      final rows = [
        for (var i = 0; i < 3; i++)
          _row(id: i + 1, name: 'R$i', streaming: ['Service$i']),
      ];
      final pie = StatisticsEngine.streamingPie(rows);
      expect(pie.hadOther, isFalse);
      expect(pie.slices.length, 3);
      expect(pie.slices.map((s) => s.label).contains('Other'), isFalse);
    });
  });

  group('StatisticsEngine.relationshipSummaries', () {
    test('counts hierarchical links and multi-entity records', () {
      final rows = [
        _row(id: 1, name: 'A', artists: ['X', 'Y'], genres: ['Jazz', 'Blues']),
        _row(id: 2, name: 'B', streaming: ['Spotify', 'Youtube']),
      ];
      final items = StatisticsEngine.relationshipSummaries(
        rows,
        genreEdges: [
          const MapEntry(1, 2),
          const MapEntry(1, 3),
        ],
        descriptorEdges: [const MapEntry(9, 10)],
      );
      final byName = {for (final i in items) i.name: i.count};
      expect(byName['Genre hierarchy links'], 2);
      expect(byName['Descriptor hierarchy links'], 1);
      expect(byName['Records with 2+ artists'], 1);
      expect(byName['Records with 2+ genres'], 1);
      expect(byName['Records with 2+ streaming links'], 1);
      expect(byName['Records with 2+ descriptors'], 0);
    });
  });
}
