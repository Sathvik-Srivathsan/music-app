import 'package:music_collection/shared/models/record_details.dart';

/// Serializes a full [RecordDetails] (record row + every joined entity in
/// stored order) into a human-readable map for the client-side audit log.
///
/// These maps are wrapped in the standard `details` shape that the log viewer
/// and [AuditLogSentence] understand:
///  * insert  → `{ 'inserted': <full tuple> }`
///  * update  → `{ 'before': <full tuple>, 'after': <full tuple> }`
///  * delete  → `{ 'deleted': <full tuple> }`
///
/// Only friendly names are included — ids are never stored here, so the log
/// can be rendered everywhere without leaking ids to non-admin users.
class RecordTupleLog {
  RecordTupleLog._();

  /// The scalar record fields plus every joined entity name.
  static Map<String, dynamic> buildFullTuple(RecordDetails r) {
    return {
      'record_name': r.record.recordName,
      'record_type': r.record.recordType,
      'release_date': r.record.releaseDate,
      'date_added': r.record.dateAdded,
      'comments': r.record.comments,
      'status': r.record.status,
      'artists': [for (final a in r.artists) a.artistName],
      'genres': [for (final g in r.genres) g.genreName],
      'descriptors': [for (final d in r.descriptors) d.descriptorName],
      'streaming': [
        for (final s in r.streaming)
          {'service_name': s.serviceName, 'service_url': s.serviceUrl},
      ],
    };
  }

  /// Convenience builders for the `details` column.
  static Map<String, dynamic> insertDetails(RecordDetails r) =>
      {'inserted': buildFullTuple(r)};

  static Map<String, dynamic> updateDetails(
      RecordDetails before, RecordDetails after) {
    return {'before': buildFullTuple(before), 'after': buildFullTuple(after)};
  }

  static Map<String, dynamic> deleteDetails(RecordDetails r) =>
      {'deleted': buildFullTuple(r)};
}
