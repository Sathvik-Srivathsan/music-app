import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_collection/core/logging/audit_outbox.dart';
import 'package:music_collection/core/logging/record_audit_logger.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/features/insert/data/repositories/insert_repository.dart';
import 'package:music_collection/features/search/data/repositories/search_repository.dart';
import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/features/search/domain/record_collation.dart';
import 'package:music_collection/features/search/domain/search_query.dart';
import 'package:music_collection/features/search/domain/taxonomy_closure.dart'
    show buildChildrenIndex, fullClosures;
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/utils/record_tuple_log.dart';

enum SearchPhase { form, loading, results }

enum ResultBucket { active, finished }

class SortColumn {
  final String field;
  bool ascending;
  SortColumn(this.field, {this.ascending = true});
}

class _GenreGroupMeta {
  final int? fIdx;
  final int familySize;
  const _GenreGroupMeta({required this.fIdx, required this.familySize});
}

class SearchProvider extends ChangeNotifier
    implements SearchResultsProvider {
  final SearchRepository _repo = SearchRepository();
  final InsertRepository _entityRepo = InsertRepository();

  List<Artist> allArtists = [];
  List<Genre> allGenres = [];
  List<Descriptor> allDescriptors = [];

  SearchPhase phase = SearchPhase.form;
  String? loadError;

  /// True when the core records read died; false when only side
  /// relations failed (rows still render, banner is a warning).
  bool loadErrorFatal = false;

  final SearchQueryParams query = SearchQueryParams();

  List<RecordDetails> _allRecords = [];
  List<RecordDetails> activeResults = [];
  List<RecordDetails> finishedResults = [];
  ResultBucket currentBucket = ResultBucket.active;

  final List<SortColumn> sortColumns = [];
  String? groupByField;

  /// Manual ordering of group keys (key -> rank). Groups without an
  /// entry keep natural order after the pinned ones; reset whenever
  /// the group-by field changes.
  final Map<String, int> groupOrderOverride = {};

  /// Taxonomy closures built from the fetched hierarchy edges.
  Map<int, Set<int>>? _genreClosure;
  Map<int, Set<int>>? _descriptorClosure;

  /// Parent->children index for BFS depth computation.
  Map<int, Set<int>>? _genreChildrenIndex;

  /// Genre ID -> minimum BFS depth from any filter ID. Null when no
  /// genre filters active or no hierarchy data.
  Map<int, int>? _genreDepthMap;

  /// Snapshot of inputs used to compute _genreDepthMap (for lazy invalidation).
  Map<int, Set<int>>? _depthInputChildren;
  String? _depthInputGenreIds;

  /// Manual column visibility overrides (field -> shown?). Absent
  /// entries fall back to the query-adaptive default; the frozen
  /// trio (name/artists/genres) never receives an entry. Reset on
  /// every new search.
  final Map<String, bool> columnVisibility = {};

  /// True once the user has manually touched any sort header this
  /// search. While false, the seeded name sort is replaced (not
  /// chained behind) by the first manual sort - record names are
  /// unique, so a secondary sort under them could never show.
  bool _userSorted = false;

  // --- Memoisation: view inputs change rarely, getters are hot ---
  int _viewVersion = 0;
  int? _sortedVersion;
  List<RecordDetails>? _sortedCache;
  int? _groupedVersion;
  List<MapEntry<String, List<RecordDetails>>>? _groupedCache;

  void _bumpView() => _viewVersion++;

  // --- id -> display-name maps (avoid linear scans per cell) ---
  final Map<int, String> _artistNames = {};
  final Map<int, String> _genreNames = {};
  final Map<int, String> _descriptorNames = {};

  void _rebuildNameMaps() {
    _artistNames
      ..clear()
      ..addEntries([for (final a in allArtists) MapEntry(a.artistId!, a.artistName)]);
    _genreNames
      ..clear()
      ..addEntries([for (final g in allGenres) MapEntry(g.genreId!, g.genreName)]);
    _descriptorNames
      ..clear()
      ..addEntries([
        for (final d in allDescriptors)
          MapEntry(d.descriptorId!, d.descriptorName),
      ]);
  }

  double fuzzyMatch(String queryText, String target) =>
      CsvUtils.calculateSimilarity(
          queryText.toLowerCase(), target.toLowerCase());

  // --- Entity name lookups (map-backed, '#id' fallback) ---
  String artistNameOf(int? id) =>
      _artistNames[id] ?? '#$id';

  String genreNameOf(int? id) => _genreNames[id] ?? '#$id';

  String descriptorNameOf(int? id) => _descriptorNames[id] ?? '#$id';

  Future<void> loadEntities() async {
    try {
      final results = await Future.wait([
        _entityRepo.fetchAllArtists(),
        _entityRepo.fetchAllGenres(),
        _entityRepo.fetchAllDescriptors(),
      ]);
      allArtists = results[0] as List<Artist>;
      allGenres = results[1] as List<Genre>;
      allDescriptors = results[2] as List<Descriptor>;
      _rebuildNameMaps();
    } catch (e) {
      loadError = 'Failed to load filter data: $e';
    }
    notifyListeners();
  }

  /// Test/diagnostic seam: installs rows and enters the results phase
  /// exactly like executeSearch's post-fetch tail, without touching
  /// the network.
  void presentRows({
    required List<RecordDetails> rows,
    List<String> legFailures = const [],
    List<MapEntry<int, int>> genreEdges = const [],
    List<MapEntry<int, int>> descriptorEdges = const [],
  }) {
    loadError =
        legFailures.isEmpty
            ? null
            : 'Partial data - some relations failed to load:\n'
                '${legFailures.join('\n\n')}';
    loadErrorFatal = false;
    _allRecords = rows;
    _genreClosure =
        genreEdges.isEmpty ? null : fullClosures(genreEdges);
    _genreChildrenIndex =
        genreEdges.isEmpty ? null : buildChildrenIndex(genreEdges);
    _descriptorClosure =
        descriptorEdges.isEmpty ? null : fullClosures(descriptorEdges);
    _applyQueryToBuckets();
    currentBucket = ResultBucket.active;
    sortColumns
      ..clear();
    if (query.genreIds.isEmpty) {
      sortColumns.add(SortColumn('name'));
    }
    groupByField = null;
    groupOrderOverride.clear();
    columnVisibility.clear();
    _userSorted = false;
    _bumpView();
    phase = SearchPhase.results;
    notifyListeners();
  }

  Future<void> executeSearch() async {
    phase = SearchPhase.loading;
    loadError = null;
    loadErrorFatal = false;
    notifyListeners();
    try {
      final result = await _repo.fetchAllRecordDetails();
      _allRecords = result.rows;
      _genreClosure = result.genreEdges.isEmpty
          ? null
          : fullClosures(result.genreEdges);
      _genreChildrenIndex = result.genreEdges.isEmpty
          ? null
          : buildChildrenIndex(result.genreEdges);
      _descriptorClosure = result.descriptorEdges.isEmpty
          ? null
          : fullClosures(result.descriptorEdges);
      if (result.hasLegFailures) {
        loadError =
            'Partial data - some relations failed to load:\n'
            '${result.legFailures.join('\n\n')}';
      }
      _applyQueryToBuckets();
      currentBucket = ResultBucket.active;
      // When genre filters are active, 0th-order genre depth sort
      // takes over — no name sort seeded so badge doesn't display.
      sortColumns
        ..clear();
      if (query.genreIds.isEmpty) {
        sortColumns.add(SortColumn('name'));
      }
      groupByField = null;
      groupOrderOverride.clear();
      columnVisibility.clear();
      _userSorted = false;
      _bumpView();
      phase = SearchPhase.results;
    } catch (e, st) {
      debugPrint('SEARCH FETCH FAILED: $e');
      debugPrint(st.toString());
      loadError = 'Search failed: $e\n\n$st';
      loadErrorFatal = true;
      phase = SearchPhase.form;
    }
    notifyListeners();
  }

  void _applyQueryToBuckets() {
    bool pass(RecordDetails r) => SearchQueryEngine.matches(
      r,
      query,
      similarity: fuzzyMatch,
      genreClosure: _genreClosure,
      descriptorClosure: _descriptorClosure,
    );
    activeResults =
        _allRecords.where((r) => !r.record.status && pass(r)).toList();
    finishedResults =
        _allRecords.where((r) => r.record.status && pass(r)).toList();
  }

  // --- Bucket / view state ---
  void backToForm() {
    phase = SearchPhase.form;
    notifyListeners();
  }

  void setBucket(ResultBucket bucket) {
    currentBucket = bucket;
    _bumpView();
    notifyListeners();
  }

  List<RecordDetails> get bucketRows => currentBucket == ResultBucket.active
      ? activeResults
      : finishedResults;

  // DB tab filter — no-op on Search tab
  @override
  String? get searchFilterField => null;

  @override
  bool get hideShowColumns => false;

  @override
  void setSearchFilterField(String? field) {}

  // Used-genre/descriptor IDs for chip dropdown filtering (Search tab)
  Set<int> get usedGenreIds {
    final source = bucketRows;
    if (source.isEmpty && _allRecords.isEmpty) {
      return {for (final g in allGenres) g.genreId!};
    }
    final ids = <int>{};
    for (final r in source) {
      for (final g in r.genres) {
        if (g.genreId != null) ids.add(g.genreId!);
      }
    }
    return ids;
  }

  Set<int> get usedDescriptorIds {
    final source = bucketRows;
    if (source.isEmpty && _allRecords.isEmpty) {
      return {for (final d in allDescriptors) d.descriptorId!};
    }
    final ids = <int>{};
    for (final r in source) {
      for (final d in r.descriptors) {
        if (d.descriptorId != null) ids.add(d.descriptorId!);
      }
    }
    return ids;
  }

  void cycleSort(String field) {
    final idx = sortColumns.indexWhere((s) => s.field == field);
    if (idx == -1) {
      // Record names are unique - chaining a secondary sort under the
      // seeded name default would never visibly change the table.
      // Replace the default on first manual touch; append otherwise.
      if (!_userSorted &&
          sortColumns.length == 1 &&
          sortColumns.first.field == 'name') {
        sortColumns
          ..clear()
          ..add(SortColumn(field));
      } else {
        sortColumns.add(SortColumn(field));
      }
      _userSorted = true;
    } else if (sortColumns[idx].ascending) {
      sortColumns[idx].ascending = false;
    } else {
      sortColumns.removeAt(idx);
    }
    _bumpView();
    notifyListeners();
  }

  void clearSorts() {
    sortColumns.clear();
    _userSorted = false;
    _bumpView();
    notifyListeners();
  }

  int sortPriority(String field) =>
      sortColumns.indexWhere((s) => s.field == field) + 1;

  void setGroupBy(String? field) {
    groupByField = field;
    groupOrderOverride.clear();
    _bumpView();
    notifyListeners();
  }

  void reorderGroups(List<String> orderedKeys) {
    groupOrderOverride
      ..clear()
      ..addEntries([
        for (var i = 0; i < orderedKeys.length; i++)
          MapEntry(orderedKeys[i], i),
      ]);
    _bumpView();
    notifyListeners();
  }

  String _sortableValue(RecordDetails r, String field) {
    switch (field) {
      case 'name':
        return r.record.recordName;
      case 'artists':
        return r.artistsCsv.toLowerCase();
      case 'genres':
        return r.genresCsv.toLowerCase();
      case 'descriptors':
        return r.descriptorsCsv.toLowerCase();
      case 'releaseDate':
        return normalizeStoredDate(r.record.releaseDate) ?? '';
      case 'type':
        return (r.record.recordType ?? '').toLowerCase();
      case 'dateAdded':
        return normalizeStoredDate(r.record.dateAdded) ?? '';
      case 'streaming':
        return r.streamingDisplayNames.join(', ').toLowerCase();
      case 'comments':
        return (r.record.comments ?? '').toLowerCase();
      default:
        return '';
    }
  }

  List<RecordDetails> get sortedRows {
    if (_sortedVersion == _viewVersion && _sortedCache != null) {
      return _sortedCache!;
    }
    final rows = List<RecordDetails>.from(bucketRows);
    if (sortColumns.isNotEmpty) {
      // User-defined sorts — genre depth is NOT applied.
      rows.sort((a, b) {
        for (final sc in sortColumns) {
          final int cmp;
          if (sc.field == 'name') {
            cmp = compareRecordNames(
                a.record.recordName, b.record.recordName);
          } else {
            cmp = _sortableValue(a, sc.field)
                .compareTo(_sortableValue(b, sc.field));
          }
          final c = sc.ascending ? cmp : -cmp;
          if (c != 0) return c;
        }
        return 0;
      });
    } else {
      // 0th order: genre depth (if genre filters active), else name.
      _ensureGenreDepthMap();
      if (_genreDepthMap != null) {
        final stats = _computeGenreMatchStats(rows);
        rows.sort((a, b) {
          final idA = a.record.recordId;
          final idB = b.record.recordId;
          final statA = idA != null ? stats[idA] : null;
          final statB = idB != null ? stats[idB] : null;
          final (countA, depthA) = statA ?? (0, 0);
          final (countB, depthB) = statB ?? (0, 0);
          if (countA != countB) return countB.compareTo(countA);
          return depthA.compareTo(depthB);
        });
      } else {
        rows.sort((a, b) => compareRecordNames(
            a.record.recordName, b.record.recordName));
      }
    }
    _sortedVersion = _viewVersion;
    _sortedCache = rows;
    return rows;
  }

  List<MapEntry<String, List<RecordDetails>>> get groupedRows {
    if (_groupedVersion == _viewVersion && _groupedCache != null) {
      return _groupedCache!;
    }
    final rows = sortedRows;
    final List<MapEntry<String, List<RecordDetails>>> result;
    if (groupByField == null) {
      result = [MapEntry('', rows)];
    } else {
      final field = groupByField!;
      final Map<String, List<RecordDetails>> out = {};
      for (final r in rows) {
        for (final key in SearchQueryEngine.groupKeysFor(r, field)) {
          (out[key] ??= []).add(r);
        }
      }
      final entries = out.entries.toList();
      if (groupOrderOverride.isNotEmpty) {
        entries.sort(_groupEntryCompare);
      } else if (field == 'genres' &&
          query.genreIds.isNotEmpty &&
          query.genresMode == StreamingFilterMode.any &&
          _genreClosure != null) {
        // Smart grouping: order genre families by filter insertion
        // order, subgenres by closure descendant count descending,
        // records within group by matched subgenre count descending.
        _applySmartGenreOrder(entries);
      }
      result = entries;
    }
    _groupedVersion = _viewVersion;
    _groupedCache = result;
    return result;
  }

  // --- Column visibility ---

  /// True for the three always-on columns, regardless of overrides or
  /// the query.
  static const _frozenCols = {'name', 'artists', 'genres'};

  /// Whether the given column should be shown, combining the user's
  /// manual overrides (if any) with the adaptive defaults computed
  /// from the current query.
  bool isColumnShown(String field) {
    if (_frozenCols.contains(field)) return true;
    final override = columnVisibility[field];
    if (override != null) return override;
    return _adaptiveShown(field);
  }

  /// The query-based adaptive rule: artists/genres always; the rest
  /// only when that parameter was used.
  bool _adaptiveShown(String field) {
    switch (field) {
      case 'descriptors':
        return query.descriptorIds.isNotEmpty;
      case 'releaseDate':
        return query.releaseOperator != null;
      case 'type':
        return query.recordTypes.isNotEmpty;
      case 'dateAdded':
        return query.addedOperator != null;
      case 'streaming':
        return query.streamingServices.isNotEmpty;
      case 'comments':
        return query.isCommentsFilled;
      default:
        return false;
    }
  }

  void setColumnVisible(String field, bool shown) {
    if (_frozenCols.contains(field)) return;
    columnVisibility[field] = shown;
    _bumpView();
    notifyListeners();
  }

  int _groupEntryCompare(
      MapEntry<String, List<RecordDetails>> a,
      MapEntry<String, List<RecordDetails>> b) {
    final ra = groupOrderOverride[a.key];
    final rb = groupOrderOverride[b.key];
    if (ra != null && rb != null) return ra.compareTo(rb);
    if (ra != null) return -1;
    if (rb != null) return 1;
    return compareRecordNames(a.key, b.key);
  }

  /// Smart genre grouping: order families by filter insertion order,
  /// subgenres within each family by closure descendant count
  /// descending, records within group by matched subgenre count
  /// descending.
  void _applySmartGenreOrder(
      List<MapEntry<String, List<RecordDetails>>> entries) {
    final closure = _genreClosure!;
    // Build genreId -> filter index (insertion order from genreIds).
    final genreToFilter = <int, int>{};
    final filterSizes = <int, int>{};
    var filterIdx = 0;
    for (final filterId in query.genreIds) {
      final family = closure[filterId] ?? {filterId};
      filterSizes[filterIdx] = family.length;
      for (final gid in family) {
        genreToFilter[gid] = filterIdx;
      }
      filterIdx++;
    }
    // Map genre name -> id for lookup.
    final nameToId = <String, int>{
      for (final g in allGenres) g.genreName: g.genreId!,
    };

    // Compute per-entry metadata for sorting.
    final meta = <int, _GenreGroupMeta>{};
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final gid = nameToId[e.key];
      final fIdx = gid != null ? genreToFilter[gid] : null;
      final familySize = closure[gid]?.length ?? 1;
      meta[i] = _GenreGroupMeta(fIdx: fIdx, familySize: familySize);
    }

    // Sort groups: filter index ascending, then family size descending.
    final indices = List<int>.generate(entries.length, (i) => i);
    indices.sort((ai, bi) {
      final ma = meta[ai]!;
      final mb = meta[bi]!;
      if (ma.fIdx != null && mb.fIdx != null) {
        final cmp = ma.fIdx!.compareTo(mb.fIdx!);
        if (cmp != 0) return cmp;
        return mb.familySize.compareTo(ma.familySize);
      }
      if (ma.fIdx != null) return -1;
      if (mb.fIdx != null) return 1;
      return compareRecordNames(entries[ai].key, entries[bi].key);
    });
    final sorted = [for (final i in indices) entries[i]];
    entries
      ..clear()
      ..addAll(sorted);

    // Within each group, sort records by matched subgenre count
    // descending (records matching more selected genres rank higher).
    for (final e in entries) {
      if (e.value.length <= 1) continue;
      e.value.sort((a, b) {
        final aCount = _matchedGenreCount(a);
        final bCount = _matchedGenreCount(b);
        final cmp = bCount.compareTo(aCount);
        if (cmp != 0) return cmp;
        return compareRecordNames(
            a.record.recordName, b.record.recordName);
      });
    }
  }

  int _matchedGenreCount(RecordDetails r) {
    int count = 0;
    for (final g in r.genres) {
      if (query.genreIds.contains(g.genreId)) count++;
    }
    return count;
  }

  /// Lazily rebuild _genreDepthMap when inputs change.
  void _ensureGenreDepthMap() {
    final childrenKey = _genreChildrenIndex;
    final genreIdsKey = query.genreIds.isEmpty
        ? ''
        : query.genreIds.join(',');
    if (_depthInputChildren == childrenKey &&
        _depthInputGenreIds == genreIdsKey) {
      return; // cached
    }
    _depthInputChildren = childrenKey;
    _depthInputGenreIds = genreIdsKey;
    if (childrenKey == null || query.genreIds.isEmpty) {
      _genreDepthMap = null;
      return;
    }
    // BFS from all filter IDs simultaneously.
    final depths = <int, int>{};
    final queue = <List<int>>[];
    for (final id in query.genreIds) {
      queue.add([id, 0]);
      depths[id] = 0;
    }
    var head = 0;
    while (head < queue.length) {
      final entry = queue[head++];
      final node = entry[0];
      final depth = entry[1];
      for (final child in childrenKey[node] ?? const <int>{}) {
        if (!depths.containsKey(child)) {
          depths[child] = depth + 1;
          queue.add([child, depth + 1]);
        }
      }
    }
    _genreDepthMap = depths;
  }

  /// Per-record (matchCount, totalDepth) for 0th-order genre sort.
  Map<int, (int, int)> _computeGenreMatchStats(
      List<RecordDetails> rows) {
    final map = _genreDepthMap;
    final stats = <int, (int, int)>{};
    for (final r in rows) {
      var count = 0;
      var totalDepth = 0;
      if (map != null) {
        for (final g in r.genres) {
          final d = map[g.genreId];
          if (d != null) {
            count++;
            totalDepth += d;
          }
        }
      }
      stats[r.record.recordId!] = (count, totalDepth);
    }
    return stats;
  }

  String groupKeyFor(RecordDetails r) {
    switch (groupByField) {
      case 'name':
        return r.record.recordName;
      case 'artists':
        return r.artistsCsv.isEmpty ? '(none)' : r.artistsCsv;
      case 'genres':
        return r.genresCsv.isEmpty ? '(none)' : r.genresCsv;
      case 'descriptors':
        return r.descriptorsCsv.isEmpty ? '(none)' : r.descriptorsCsv;
      case 'releaseDate':
        return formatDisplayDate(
                r.record.releaseDate, r.record.releaseDateMask) ??
            '(unknown)';
      case 'type':
        return r.record.recordType ?? '(none)';
      case 'dateAdded':
        return r.record.dateAdded ?? '(unknown)';
      case 'streaming':
        final s = r.streamingDisplayNames.join(', ');
        return s.isEmpty ? '(no streaming)' : s;
      case 'comments':
        return (r.record.comments ?? '').isEmpty ? '(none)' : 'Has comments';
      default:
        return '';
    }
  }

  int get totalRows => bucketRows.length;

  // --- Edit popup operations ---
  Future<String?> saveEdits(RecordDetails edited,
      {String originTab = 'search'}) async {
    try {
      final id = edited.record.recordId!;
      final idx = _allRecords.indexWhere((r) => r.record.recordId == id);
      final before = idx != -1 ? _allRecords[idx] : edited;

      // Enqueue the full before/after intent BEFORE the write so a crash
      // between the data write and the log write is recovered on next launch.
      final opId = await AuditOutbox.shared.enqueue(
        action: 'update',
        details: RecordTupleLog.updateDetails(before, edited),
        recordId: id,
        originTab: originTab,
      );

      await _repo.updateFullRecord(edited, originTab: originTab);
      if (idx != -1) {
        _allRecords[idx] = edited;
        unawaited(RecordAuditLogger.logRecordUpdate(
          before: before,
          after: edited,
          originTab: originTab,
          opId: opId,
        ));
      }
      _applyQueryToBuckets();
      notifyListeners();
      return null;
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> deleteById(int recordId,
      {String originTab = 'search'}) async {
    try {
      final idx = _allRecords.indexWhere((r) => r.record.recordId == recordId);
      final deleted = idx != -1 ? _allRecords[idx] : null;

      // Enqueue BEFORE the delete so the pre-delete tuple survives a crash.
      final opId = await AuditOutbox.shared.enqueue(
        action: 'delete',
        details: deleted != null
            ? RecordTupleLog.deleteDetails(deleted)
            : const <String, dynamic>{},
        recordId: recordId,
        originTab: originTab,
      );

      await _repo.deleteRecord(recordId, originTab: originTab);
      if (deleted != null) {
        unawaited(RecordAuditLogger.logRecordAction(
          action: 'delete',
          details: deleted,
          originTab: originTab,
          opId: opId,
        ));
        _allRecords.removeAt(idx);
      }
      _applyQueryToBuckets();
      notifyListeners();
      return null;
    } catch (e) {
      return '$e';
    }
  }
}
