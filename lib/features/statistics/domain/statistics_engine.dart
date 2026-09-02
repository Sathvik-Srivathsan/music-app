import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/shared/models/record_details.dart';

/// A single labeled value used by both pie slices and legend rows.
class StatSlice {
  final String label;
  final int value;
  const StatSlice(this.label, this.value);

  @override
  bool operator ==(Object other) =>
      other is StatSlice && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => '$label: $value';
}

/// A single bar (category -> count) for bar charts.
class StatBar {
  final String label;
  final int value;
  const StatBar(this.label, this.value);

  @override
  bool operator ==(Object other) =>
      other is StatBar && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => '$label: $value';
}

/// A named entity with an integer count (top-k results).
class EntityCount {
  final int? id;
  final String name;
  final int count;
  const EntityCount(this.id, this.name, this.count);

  @override
  String toString() => '$name: $count';
}

/// Aggregate headline numbers for the Overview section.
class OverviewStats {
  final int totalRecords;
  final int activeRecords;
  final int finishedRecords;
  final int totalArtists;
  final int totalGenres;
  final int totalDescriptors;
  final int totalStreamingLinks;
  final int recordsWithStreaming;
  final int recordsWithUnknownYear;
  const OverviewStats({
    required this.totalRecords,
    required this.activeRecords,
    required this.finishedRecords,
    required this.totalArtists,
    required this.totalGenres,
    required this.totalDescriptors,
    required this.totalStreamingLinks,
    required this.recordsWithStreaming,
    required this.recordsWithUnknownYear,
  });
}

/// Result of a streaming pie aggregation (already limited to <= 6 slices).
class StreamingPie {
  final List<StatSlice> slices;
  final bool hadOther;
  const StreamingPie({required this.slices, required this.hadOther});
}

/// Result of a song-per-decade aggregation.
class DecadeData {
  final List<StatBar> buckets; // asc by decade, Unknown always last
  final int unknownCount;
  const DecadeData({required this.buckets, required this.unknownCount});
}

/// Pure, dependency-light aggregation helpers for the Statistics tab.
///
/// Every method is a pure function over [List<RecordDetails>] (plus optional
/// hierarchy edges) so the logic can be unit-tested without a network/mock.
class StatisticsEngine {
  StatisticsEngine._();

  /// Maximum number of pie slices before the tail collapses to "Other".
  static const int maxPieSlices = 6;

  /// Default top-k cap for entity bar charts.
  static const int defaultTopK = 10;

  /// The release year of a record, or null when it cannot be parsed.
  static int? yearOf(RecordDetails row) =>
      PartialDate.tryParse(row.record.releaseDate ?? '')?.year;

  /// The decade floor (year - year%10), or null when the year is unknown.
  static int? decadeOf(RecordDetails row) {
    final y = yearOf(row);
    return y == null ? null : y - (y % 10);
  }

  /// Distinct artist count across all records.
  static int distinctArtists(List<RecordDetails> rows) =>
      rows.expand((r) => r.artists).map((a) => a.artistId ?? a.artistName).toSet().length;

  /// Distinct genre count across all records.
  static int distinctGenres(List<RecordDetails> rows) =>
      rows.expand((r) => r.genres).map((g) => g.genreId ?? g.genreName).toSet().length;

  /// Distinct descriptor count across all records.
  static int distinctDescriptors(List<RecordDetails> rows) =>
      rows.expand((r) => r.descriptors).map((d) => d.descriptorId ?? d.descriptorName).toSet().length;

  /// Records that have at least one streaming link.
  static int recordsWithStreaming(List<RecordDetails> rows) =>
      rows.where((r) => r.streaming.isNotEmpty).length;

  /// Aggregate headline numbers for the Overview section.
  static OverviewStats computeOverview(List<RecordDetails> rows) {
    var active = 0;
    var finished = 0;
    var unknownYear = 0;
    for (final r in rows) {
      if (r.record.status) {
        finished++;
      } else {
        active++;
      }
      if (yearOf(r) == null) unknownYear++;
    }
    return OverviewStats(
      totalRecords: rows.length,
      activeRecords: active,
      finishedRecords: finished,
      totalArtists: distinctArtists(rows),
      totalGenres: distinctGenres(rows),
      totalDescriptors: distinctDescriptors(rows),
      totalStreamingLinks:
          rows.fold<int>(0, (sum, r) => sum + r.streaming.length),
      recordsWithStreaming: recordsWithStreaming(rows),
      recordsWithUnknownYear: unknownYear,
    );
  }

  /// Active vs Finished breakdown (always exactly 2 slices, never collapsed).
  static List<StatSlice> statusSlices(List<RecordDetails> rows) {
    final o = computeOverview(rows);
    return [
      StatSlice('Active', o.activeRecords),
      StatSlice('Finished', o.finishedRecords),
    ];
  }

  /// Records per decade (asc), with an "Unknown" bucket always appended last
  /// for records whose year could not be parsed. Unknown records are never
  /// dropped.
  static DecadeData decadeData(List<RecordDetails> rows) {
    final map = <int, int>{};
    var unknown = 0;
    for (final r in rows) {
      final d = decadeOf(r);
      if (d == null) {
        unknown++;
      } else {
        map[d] = (map[d] ?? 0) + 1;
      }
    }
    final decades = map.keys.toList()..sort();
    final buckets = <StatBar>[
      for (final d in decades) StatBar('${d}s', map[d]!),
      if (unknown > 0) StatBar('Unknown', unknown),
    ];
    return DecadeData(buckets: buckets, unknownCount: unknown);
  }

  /// Records per record type, sorted descending by count (top-k, capped).
  static List<StatBar> recordTypeBars(List<RecordDetails> rows, {int? top}) {
    return _topBars(
      rows.map((r) => r.record.recordType ?? 'Unknown').toList(),
      top: top ?? defaultTopK,
    );
  }

  /// Top artists by number of records (desc). An artist with multiple records
  /// counts once per record they appear on.
  static List<EntityCount> topArtists(List<RecordDetails> rows, {int? top}) =>
      _topEntities(
        rows.expand((r) => r.artists).map((a) => (a.artistId, a.artistName)).toList(),
        top: top ?? defaultTopK,
      );

  /// Top genres by number of records (desc).
  static List<EntityCount> topGenres(List<RecordDetails> rows, {int? top}) =>
      _topEntities(
        rows.expand((r) => r.genres).map((g) => (g.genreId, g.genreName)).toList(),
        top: top ?? defaultTopK,
      );

  /// Top descriptors by number of records (desc).
  static List<EntityCount> topDescriptors(List<RecordDetails> rows, {int? top}) =>
      _topEntities(
        rows.expand((r) => r.descriptors).map((d) => (d.descriptorId, d.descriptorName)).toList(),
        top: top ?? defaultTopK,
      );

  /// Records per explicit streaming service as a pie. NULL / empty service
  /// names (legacy rows) map to "No service listed". Result is capped at
  /// [maxPieSlices]; the tail collapses into an "Other" slice.
  static StreamingPie streamingPie(List<RecordDetails> rows) {
    final map = <String, int>{};
    for (final r in rows) {
      if (r.streaming.isEmpty) {
        map['No service listed'] = (map['No service listed'] ?? 0) + 1;
        continue;
      }
      final names = <String>{};
      for (final s in r.streaming) {
        names.add(AppConstants.streamingToDisplay(s.serviceName.isEmpty
            ? 'No service listed'
            : s.serviceName));
      }
      for (final n in names) {
        map[n] = (map[n] ?? 0) + 1;
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = <StatSlice>[
      for (final e in entries) StatSlice(e.key, e.value),
    ];
    return _collapseSlices(slices, maxPieSlices);
  }

  /// Count of taxonomy hierarchy edges from a raw parent->child edge list.
  static EntityCount _edgeSummary(String label, List<MapEntry<int, int>> edges) =>
      EntityCount(null, label, edges.length);

  static List<EntityCount> relationshipSummaries(
    List<RecordDetails> rows, {
    required List<MapEntry<int, int>> genreEdges,
    required List<MapEntry<int, int>> descriptorEdges,
  }) {
    var multiArtist = 0;
    var multiGenre = 0;
    var multiDescriptor = 0;
    var multiStreaming = 0;
    for (final r in rows) {
      if (r.artists.length > 1) multiArtist++;
      if (r.genres.length > 1) multiGenre++;
      if (r.descriptors.length > 1) multiDescriptor++;
      if (r.streaming.length > 1) multiStreaming++;
    }
    return [
      EntityCount(null, 'Genre hierarchy links', _edgeSummary('', genreEdges).count),
      EntityCount(null, 'Descriptor hierarchy links', _edgeSummary('', descriptorEdges).count),
      EntityCount(null, 'Records with 2+ artists', multiArtist),
      EntityCount(null, 'Records with 2+ genres', multiGenre),
      EntityCount(null, 'Records with 2+ descriptors', multiDescriptor),
      EntityCount(null, 'Records with 2+ streaming links', multiStreaming),
    ];
  }

  // ---- internal helpers ----------------------------------------------------

  static List<StatBar> _topBars(List<String> labels, {required int top}) {
    final map = <String, int>{};
    for (final l in labels) {
      map[l] = (map[l] ?? 0) + 1;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final bars = <StatBar>[
      for (final e in entries.take(top)) StatBar(e.key, e.value),
    ];
    return _sortBarsDesc(bars);
  }

  static List<EntityCount> _topEntities(
    List<(int?, String)> tuples, {
    required int top,
  }) {
    final map = <String, ({int? id, int count})>{};
    for (final (id, name) in tuples) {
      final cur = map[name];
      map[name] = (
        id: id,
        count: (cur?.count ?? 0) + 1,
      );
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    return [
      for (final e in entries.take(top))
        EntityCount(e.value.id, e.key, e.value.count),
    ];
  }

  /// Collapses a sorted slice list so it has at most [max] entries; surplus is
  /// merged into an "Other" slice appended last. Returns a plain list.
  static StreamingPie _collapseSlices(List<StatSlice> slices, int max) {
    if (slices.length <= max) return StreamingPie(slices: slices, hadOther: false);
    final head = slices.sublist(0, max - 1);
    final tail = slices.sublist(max - 1);
    final otherValue = tail.fold<int>(0, (s, c) => s + c.value);
    return StreamingPie(
      slices: [...head, StatSlice('Other', otherValue)],
      hadOther: true,
    );
  }

  static List<StatBar> _sortBarsDesc(List<StatBar> bars) =>
      [...bars]..sort((a, b) => b.value.compareTo(a.value));
}
