import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/shared/models/record_details.dart';

enum StreamingFilterMode { any, all }

extension StreamingFilterModeLabel on StreamingFilterMode {
  String get label => this == StreamingFilterMode.any ? 'ANY' : 'ALL';
}

/// The full query built from the SEARCH form. AND across categories;
/// within Artists / Genres / Descriptors multiple chips match per that
/// category's own OR/ALL switch (Artists are always ANY).
class SearchQueryParams {
  String nameText = '';
  String commentsText = '';
  final Set<int> artistIds = {};
  final Set<int> genreIds = <int>{};
  final Set<int> descriptorIds = {};
  StreamingFilterMode genresMode = StreamingFilterMode.any;
  StreamingFilterMode descriptorsMode = StreamingFilterMode.any;
  final Set<String> recordTypes = {};
  DateOperator? releaseOperator;
  String releaseValue1 = '';
  String releaseValue2 = '';
  DateOperator? addedOperator;
  String addedValue1 = '';
  String addedValue2 = '';
  final Set<String> streamingServices = {};
  StreamingFilterMode streamingMode = StreamingFilterMode.any;

  bool get isNameFilled => nameText.trim().isNotEmpty;

  bool get isCommentsFilled => commentsText.trim().isNotEmpty;

  bool get isEmpty =>
      !isNameFilled &&
      !isCommentsFilled &&
      artistIds.isEmpty &&
      genreIds.isEmpty &&
      descriptorIds.isEmpty &&
      recordTypes.isEmpty &&
      releaseOperator == null &&
      addedOperator == null &&
      streamingServices.isEmpty;

  bool get isFilled => !isEmpty;

  void clear() {
    nameText = '';
    commentsText = '';
    artistIds.clear();
    genreIds.clear();
    descriptorIds.clear();
    genresMode = StreamingFilterMode.any;
    descriptorsMode = StreamingFilterMode.any;
    recordTypes.clear();
    releaseOperator = null;
    releaseValue1 = '';
    releaseValue2 = '';
    addedOperator = null;
    addedValue1 = '';
    addedValue2 = '';
    streamingServices.clear();
    streamingMode = StreamingFilterMode.any;
  }
}

class SearchQueryEngine {
  /// Threshold mirrors the dropdown suggestion filter in TAB 1.
  static const double fuzzyThreshold = 0.3;

  static bool matches(
    RecordDetails r,
    SearchQueryParams q, {
    double Function(String query, String target)? similarity,
    Map<int, Set<int>>? genreClosure,
    Map<int, Set<int>>? descriptorClosure,
  }) {
    if (q.isNameFilled &&
        !_matchesName(r.record.recordName, q.nameText, similarity)) {
      return false;
    }

    if (q.isCommentsFilled) {
      // Fuzzy type-2 only - no substring shortcut for comments.
      final s = similarity?.call(
              q.commentsText.trim(), r.record.comments ?? '') ??
          0.0;
      if (s <= fuzzyThreshold) return false;
    }

    if (q.artistIds.isNotEmpty &&
        !r.artists.any((a) => q.artistIds.contains(a.artistId))) {
      return false;
    }

    if (q.genreIds.isNotEmpty) {
      if (!_taxonomyMatch(
        selected: q.genreIds,
        recordIds: [for (final g in r.genres) g.genreId],
        mode: q.genresMode,
        closure: genreClosure,
      )) {
        return false;
      }
    }

    if (q.descriptorIds.isNotEmpty) {
      if (!_taxonomyMatch(
        selected: q.descriptorIds,
        recordIds: [for (final d in r.descriptors) d.descriptorId],
        mode: q.descriptorsMode,
        closure: descriptorClosure,
      )) {
        return false;
      }
    }

    if (q.recordTypes.isNotEmpty &&
        (r.record.recordType == null ||
            !q.recordTypes.contains(r.record.recordType))) {
      return false;
    }

    if (q.releaseOperator != null &&
        !dateMatches(
          recordValue: r.record.releaseDate,
          operator: q.releaseOperator!,
          queryValue1: q.releaseValue1,
          queryValue2: q.releaseValue2,
        )) {
      return false;
    }

    if (q.addedOperator != null &&
        !dateMatches(
          recordValue: r.record.dateAdded,
          operator: q.addedOperator!,
          queryValue1: q.addedValue1,
          queryValue2: q.addedValue2,
        )) {
      return false;
    }

    if (q.streamingServices.isNotEmpty) {
      final owned = r.streamingDisplayNames.toSet();
      if (q.streamingMode == StreamingFilterMode.any) {
        if (!owned.any(q.streamingServices.contains)) return false;
      } else {
        if (!owned.containsAll(q.streamingServices)) return false;
      }
    }

    return true;
  }

  /// Taxonomy matching with hierarchy expansion. Without a closure
  /// the check is plain id membership (legacy behaviour). With one,
  /// ANY mode hits when a record id lies in the union of the selected
  /// ids' descendant closures; ALL mode requires every selected id's
  /// closure to intersect the record's set.
  static bool _taxonomyMatch({
    required Iterable<int> selected,
    required List<int?> recordIds,
    required StreamingFilterMode mode,
    required Map<int, Set<int>>? closure,
  }) {
    if (closure == null) {
      final rec = recordIds.whereType<int>().toSet();
      return mode == StreamingFilterMode.any
          ? selected.any(rec.contains)
          : rec.containsAll(selected);
    }
    final own = recordIds.whereType<int>().toSet();
    if (mode == StreamingFilterMode.any) {
      return selected.any((s) =>
          (closure[s] ?? {s}).any(own.contains));
    }
    return selected.every((s) =>
        (closure[s] ?? {s}).any(own.contains));
  }

  /// Group keys for a record under [field]. Multi-value fields
  /// (artists/genres/descriptors) yield ONE KEY PER VALUE - a record
  /// with Jazz+Fusion appears under both groups; empty yields a
  /// single '(none)'.
  static List<String> groupKeysFor(RecordDetails r, String field) {
    switch (field) {
      case 'artists':
        return r.artists.isEmpty
            ? const ['(none)']
            : [for (final a in r.artists) a.artistName];
      case 'genres':
        return r.genres.isEmpty
            ? const ['(none)']
            : [for (final g in r.genres) g.genreName];
      case 'descriptors':
        return r.descriptors.isEmpty
            ? const ['(none)']
            : [for (final d in r.descriptors) d.descriptorName];
      case 'name':
        return [r.record.recordName];
      case 'releaseDate':
        return [
          formatDisplayDate(
                  r.record.releaseDate, r.record.releaseDateMask) ??
              '(unknown)'
        ];
      case 'type':
        return [r.record.recordType ?? '(none)'];
      case 'dateAdded':
        return [r.record.dateAdded ?? '(unknown)'];
      case 'streaming':
        final s = r.streamingDisplayNames.join(', ');
        return [s.isEmpty ? '(no streaming)' : s];
      case 'comments':
        return [(r.record.comments ?? '').isEmpty
            ? '(none)'
            : 'Has comments'];
      default:
        return const [''];
    }
  }

  static bool _matchesName(
    String recordName,
    String needle,
    double Function(String, String)? similarity,
  ) {
    final n = needle.trim().toLowerCase();
    final h = recordName.toLowerCase();
    if (h.contains(n)) return true;
    if (similarity == null) return false;
    return similarity(needle.trim(), recordName) > fuzzyThreshold;
  }

  /// Resolves a set of entity IDs to display names, truncated at 5
  /// with "...and N more" when [nameResolver] is provided.
  /// Falls back to count when resolver is null or IDs can't be resolved.
  static String _resolveNames(
    Set<int> ids,
    Map<int, String>? nameResolver,
    String mode,
  ) {
    if (nameResolver == null) {
      return '${ids.length} selected ($mode)';
    }
    final names = [for (final id in ids) nameResolver[id] ?? '#$id'];
    if (names.length <= 5) {
      return '${names.join(', ')} ($mode)';
    }
    final shown = names.take(5).join(', ');
    final remaining = names.length - 5;
    return '$shown ...and $remaining more ($mode)';
  }

  /// Option A preview: plain-text parameter summary. Only filled
  /// parameters are listed; an empty query says so explicitly.
  /// Entity IDs are resolved to names via the per-type name maps
  /// ([artistNames] / [genreNames] / [descriptorNames], truncated at 5
  /// with "...and N more" for long lists). The maps are passed SEPARATELY
  /// per category so artists, genres and descriptors can never shadow each
  /// other even when their numeric IDs collide (each table has its own ID
  /// space, so e.g. artist id 5 and descriptor id 5 are different things).
  static List<MapEntry<String, String>> previewLines(
    SearchQueryParams q, {
    Map<int, String>? artistNames,
    Map<int, String>? genreNames,
    Map<int, String>? descriptorNames,
  }) {
    final lines = <MapEntry<String, String>>[];

    if (q.isEmpty) {
      lines.add(const MapEntry('Parameters', 'None - returning ALL records'));
      return lines;
    }

    if (q.isNameFilled) {
      lines.add(MapEntry('Record Name', 'fuzzy match: "${q.nameText.trim()}"'));
    }
    if (q.isCommentsFilled) {
      lines.add(MapEntry(
          'Comments', 'fuzzy match: "${q.commentsText.trim()}"'));
    }
    if (q.artistIds.isNotEmpty) {
      lines.add(MapEntry('Artists',
          _resolveNames(q.artistIds, artistNames, 'ANY')));
    }
    if (q.genreIds.isNotEmpty) {
      lines.add(MapEntry('Genres',
          _resolveNames(q.genreIds, genreNames, q.genresMode.label)));
    }
    if (q.descriptorIds.isNotEmpty) {
      lines.add(MapEntry('Descriptors',
          _resolveNames(q.descriptorIds, descriptorNames, q.descriptorsMode.label)));
    }
    if (q.recordTypes.isNotEmpty) {
      lines.add(MapEntry('Record Types', '${q.recordTypes.join(', ')} (ANY)'));
    }
    String norm(String v) => parseFlexibleDate(v) ?? v.trim();
    if (q.releaseOperator != null) {
      var v = '${q.releaseOperator!.label}: ${norm(q.releaseValue1)}';
      if (q.releaseOperator!.needsSecondValue) {
        v += ' to ${norm(q.releaseValue2)}';
      }
      lines.add(MapEntry('Release Date', v));
    }
    if (q.addedOperator != null) {
      var v = '${q.addedOperator!.label}: ${norm(q.addedValue1)}';
      if (q.addedOperator!.needsSecondValue) {
        v += ' to ${norm(q.addedValue2)}';
      }
      lines.add(MapEntry('Date Added', v));
    }
    if (q.streamingServices.isNotEmpty) {
      lines.add(MapEntry(
        'Streaming',
        '${q.streamingServices.join(', ')} (${q.streamingMode.label})',
      ));
    }
    return lines;
  }
}
