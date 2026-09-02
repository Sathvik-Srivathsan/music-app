import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';
import 'package:music_collection/shared/utils/record_tuple_log.dart';

RecordDetails _details() {
  return RecordDetails(
    record: Record(
      recordId: 7,
      recordName: 'Kind of Blue',
      recordType: 'Album',
      releaseDate: '1959-08-17',
      dateAdded: '05/07/2026',
      comments: 'modal jazz',
      status: false,
    ),
    artists: [
      Artist(artistId: 1, artistName: 'Miles Davis'),
      Artist(artistId: 2, artistName: 'John Coltrane'),
    ],
    genres: [
      Genre(genreId: 1, genreName: 'Jazz'),
      Genre(genreId: 2, genreName: 'Modal'),
    ],
    descriptors: [
      Descriptor(descriptorId: 1, descriptorName: 'Blue Note'),
    ],
    streaming: [
      StreamingService(serviceName: 'Spotify', serviceUrl: 'http://sp'),
      StreamingService(serviceName: 'Tidal', serviceUrl: ''),
    ],
  );
}

void main() {
  group('RecordTupleLog.buildFullTuple', () {
    test('captures record scalar fields', () {
      final t = RecordTupleLog.buildFullTuple(_details());
      expect(t['record_name'], 'Kind of Blue');
      expect(t['record_type'], 'Album');
      expect(t['release_date'], '1959-08-17');
      expect(t['date_added'], '05/07/2026');
      expect(t['comments'], 'modal jazz');
      expect(t['status'], false);
    });

    test('orders artists, genres, descriptors by stored order', () {
      final t = RecordTupleLog.buildFullTuple(_details());
      expect(t['artists'], ['Miles Davis', 'John Coltrane']);
      expect(t['genres'], ['Jazz', 'Modal']);
      expect(t['descriptors'], ['Blue Note']);
    });

    test('streaming is a list of service maps', () {
      final t = RecordTupleLog.buildFullTuple(_details());
      expect(t['streaming'], [
        {'service_name': 'Spotify', 'service_url': 'http://sp'},
        {'service_name': 'Tidal', 'service_url': ''},
      ]);
    });

    test('never leaks ids', () {
      final t = RecordTupleLog.buildFullTuple(_details());
      final json = t.toString();
      expect(json, isNot(contains('recordId')));
      expect(json, isNot(contains('artistId')));
      expect(json, isNot(contains('genreId')));
      expect(json, isNot(contains('descriptorId')));
    });
  });

  group('RecordTupleLog details builders', () {
    test('insert wraps tuple under inserted', () {
      final d = RecordTupleLog.insertDetails(_details());
      expect(d.keys, ['inserted']);
      expect((d['inserted'] as Map)['record_name'], 'Kind of Blue');
    });

    test('update wraps before and after', () {
      final d = RecordTupleLog.updateDetails(_details(), _details());
      expect(d.keys.toSet(), {'before', 'after'});
    });

    test('delete wraps tuple under deleted', () {
      final d = RecordTupleLog.deleteDetails(_details());
      expect(d.keys, ['deleted']);
    });
  });
}
