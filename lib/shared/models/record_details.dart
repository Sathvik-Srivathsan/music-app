import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/streaming_service.dart';

/// A fully reconstructed record: the row plus every joined entity in
/// stored order. This is what SEARCH results and the edit popup work
/// with.
class RecordDetails {
  final Record record;
  final List<Artist> artists;
  final List<Genre> genres;
  final List<Descriptor> descriptors;
  final List<StreamingService> streaming;

  RecordDetails({
    required this.record,
    required this.artists,
    required this.genres,
    required this.descriptors,
    required this.streaming,
  });

  factory RecordDetails.fromJson(Map<String, dynamic> json) {
    return RecordDetails(
      record: Record.fromJson(json['record'] as Map<String, dynamic>),
      artists: (json['artists'] as List<dynamic>? ?? [])
          .map((e) => Artist.fromJson(e as Map<String, dynamic>))
          .toList(),
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
      descriptors: (json['descriptors'] as List<dynamic>? ?? [])
          .map((e) => Descriptor.fromJson(e as Map<String, dynamic>))
          .toList(),
      streaming: (json['streaming'] as List<dynamic>? ?? [])
          .map((e) => StreamingService.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get artistsCsv => artists.map((a) => a.artistName).join(', ');
  String get genresCsv => genres.map((g) => g.genreName).join(', ');
  String get descriptorsCsv =>
      descriptors.map((d) => d.descriptorName).join(', ');

  /// Display names of streaming services (DB values mapped back).
  Iterable<String> get streamingDisplayNames => streaming
      .map((s) => s.serviceName)
      .map(_dbToDisplay);

  static String _dbToDisplay(String db) {
    const special = {'SoulSeekQT': 'SoulSeekQT (SSQT)'};
    return special[db] ?? db;
  }
}
