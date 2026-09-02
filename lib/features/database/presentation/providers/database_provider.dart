import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_collection/core/logging/audit_outbox.dart';
import 'package:music_collection/core/logging/record_audit_logger.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/features/insert/data/repositories/insert_repository.dart';
import 'package:music_collection/features/search/data/repositories/search_repository.dart';
import 'package:music_collection/features/search/domain/record_collation.dart';
import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/features/search/domain/search_query.dart';
import 'package:music_collection/features/search/presentation/providers/search_provider.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/utils/record_tuple_log.dart';

class DatabaseProvider extends ChangeNotifier
    implements SearchResultsProvider {
  final SearchRepository _repo = SearchRepository();
  final InsertRepository _entityRepo = InsertRepository();

  List<Artist> allArtists = [];
  List<Genre> allGenres = [];
  List<Descriptor> allDescriptors = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _searchFilterField;
  @override
  String? get searchFilterField => _searchFilterField;

  List<RecordDetails> _allRecords = [];
  List<RecordDetails> _filteredRecords = [];

  bool get isLoaded => _allRecords.isNotEmpty || _isLoading;

  List<RecordDetails> activeResults = [];
  List<RecordDetails> finishedResults = [];
  ResultBucket currentBucket = ResultBucket.active;

  final List<SortColumn> sortColumns = [SortColumn('name')];
  bool _userSorted = true;
  String? groupByField;
  final Map<String, int> groupOrderOverride = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? loadError;

  int _viewVersion = 0;
  int _sortedVersion = -1;
  List<RecordDetails>? _sortedCache;
  int _groupedVersion = -1;
  List<MapEntry<String, List<RecordDetails>>>? _groupedCache;

  SearchQueryParams get query => SearchQueryParams();

  @override
  bool get hideShowColumns => true;

  // ── Static filter field labels ────────────────────────────────

  static const filterFieldLabels = <String, String>{
    'name': 'Record Name',
    'artists': 'Artists',
    'genres': 'Genres',
    'descriptors': 'Descriptors',
    'releaseDate': 'Release Date',
    'dateAdded': 'Date Added',
    'type': 'Record Type',
    'comments': 'Comments',
    'streaming': 'Streaming',
  };

  // ── Test seam: inject rows without hitting the network ─────────

  void presentRows({
    required List<RecordDetails> rows,
    List<Artist>? artists,
    List<Genre>? genres,
    List<Descriptor>? descriptors,
  }) {
    loadError = null;
    _allRecords = rows;
    _splitBuckets();
    _filteredRecords = rows;
    _searchQuery = '';
    _searchFilterField = null;
    if (artists != null) allArtists = artists;
    if (genres != null) allGenres = genres;
    if (descriptors != null) allDescriptors = descriptors;
    sortColumns
      ..clear()
      ..add(SortColumn('name'));
    _userSorted = true;
    groupByField = null;
    groupOrderOverride.clear();
    _bumpView();
    notifyListeners();
  }

  // ── Data Loading ──────────────────────────────────────────────

  Future<void> loadAllRecords() async {
    _isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final result = await _repo.fetchAllRecordDetails();
      _allRecords = result.rows;
      _splitBuckets();
      _applySearch();
      _isLoading = false;
      _bumpView();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      loadError = '$e';
      notifyListeners();
    }
  }

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
      notifyListeners();
    } catch (_) {}
  }

  void _splitBuckets() {
    activeResults = _allRecords.where((r) => !r.record.status).toList();
    finishedResults = _allRecords.where((r) => r.record.status).toList();
  }

  // ── Bucket Toggle (subsection switch = full clear) ────────────

  void setBucket(ResultBucket bucket) {
    currentBucket = bucket;
    _searchQuery = '';
    _searchFilterField = null;
    sortColumns.clear();
    _userSorted = false;
    groupByField = null;
    groupOrderOverride.clear();
    _applySearch();
    _bumpView();
    notifyListeners();
  }

  List<RecordDetails> get bucketRows =>
      currentBucket == ResultBucket.active ? activeResults : finishedResults;

  // ── Fuzzy Search ──────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearch();
    _bumpView();
    notifyListeners();
  }

  @override
  void setSearchFilterField(String? field) {
    _searchFilterField = field;
    _applySearch();
    _bumpView();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchFilterField = null;
    _applySearch();
    _bumpView();
    notifyListeners();
  }

  void _applySearch() {
    final source = bucketRows;
    if (_searchQuery.trim().isEmpty) {
      _filteredRecords = source;
      return;
    }
    final q = _searchQuery.trim().toLowerCase();
    final scored = <_ScoredRecord>[];
    for (final r in source) {
      final text = _searchFilterField != null
          ? _fieldText(r, _searchFilterField!).toLowerCase()
          : _buildSearchText(r).toLowerCase();
      if (text.isEmpty) continue;
      final contains = text.contains(q);
      final score =
          contains ? 1.0 : CsvUtils.calculateSimilarity(q, text);
      if (contains || score > 0.3) {
        scored.add(_ScoredRecord(r, score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    _filteredRecords = [for (final s in scored) s.record];
  }

  static String _fieldText(RecordDetails r, String field) {
    switch (field) {
      case 'name':
        return r.record.recordName;
      case 'artists':
        return r.artistsCsv;
      case 'genres':
        return r.genresCsv;
      case 'descriptors':
        return r.descriptorsCsv;
      case 'releaseDate':
        return formatDisplayDate(
                r.record.releaseDate, r.record.releaseDateMask) ??
            '';
      case 'dateAdded':
        return r.record.dateAdded ?? '';
      case 'type':
        return r.record.recordType ?? '';
      case 'comments':
        return r.record.comments ?? '';
      case 'streaming':
        return r.streamingDisplayNames.join(' ');
      default:
        return '';
    }
  }

  static String _buildSearchText(RecordDetails r) {
    final parts = <String>[
      r.record.recordName,
      r.artistsCsv,
      r.genresCsv,
      r.descriptorsCsv,
      r.record.releaseDate ?? '',
      r.record.dateAdded ?? '',
      r.record.recordType ?? '',
      r.record.comments ?? '',
      r.streamingDisplayNames.join(' '),
    ];
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  // ── Sorting (same as SearchProvider) ──────────────────────────

  void cycleSort(String field) {
    final idx = sortColumns.indexWhere((s) => s.field == field);
    if (idx == -1) {
      if (!_userSorted &&
          sortColumns.length == 1 &&
          sortColumns[0].field == 'name') {
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

  // ── Grouping (same as SearchProvider) ──────────────────────────

  void setGroupBy(String? field) {
    groupByField = field;
    groupOrderOverride.clear();
    _bumpView();
    notifyListeners();
  }

  void reorderGroups(List<String> orderedKeys) {
    groupOrderOverride.clear();
    for (var i = 0; i < orderedKeys.length; i++) {
      groupOrderOverride[orderedKeys[i]] = i;
    }
    _bumpView();
    notifyListeners();
  }

  // ── Column Visibility (always show all) ──────────────────────

  @override
  bool isColumnShown(String field) => true;

  @override
  void setColumnVisible(String field, bool shown) {}

  // ── Used genre/descriptor IDs for chip filtering ──────────────

  Set<int> get usedGenreIds {
    final source = _filteredRecords;
    if (source.isEmpty && _allRecords.isEmpty) {
      return {for (final g in allGenres) if (g.genreId != null) g.genreId!};
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
    final source = _filteredRecords;
    if (source.isEmpty && _allRecords.isEmpty) {
      return {
        for (final d in allDescriptors)
          if (d.descriptorId != null) d.descriptorId!
      };
    }
    final ids = <int>{};
    for (final r in source) {
      for (final d in r.descriptors) {
        if (d.descriptorId != null) ids.add(d.descriptorId!);
      }
    }
    return ids;
  }

  // ── Memoized Getters ──────────────────────────────────────────

  void _bumpView() {
    _viewVersion++;
  }

  List<RecordDetails> get sortedRows {
    if (_sortedVersion == _viewVersion && _sortedCache != null) {
      return _sortedCache!;
    }
    final list = List<RecordDetails>.from(_filteredRecords);
    if (sortColumns.isNotEmpty) {
      list.sort((a, b) {
        for (final sc in sortColumns) {
          int cmp;
          if (sc.field == 'name') {
            cmp = compareRecordNames(
                a.record.recordName, b.record.recordName);
          } else {
            cmp = _sortableValue(a, sc.field)
                .compareTo(_sortableValue(b, sc.field));
          }
          if (cmp != 0) return sc.ascending ? cmp : -cmp;
        }
        return 0;
      });
    }
    _sortedCache = list;
    _sortedVersion = _viewVersion;
    return list;
  }

  static String _sortableValue(RecordDetails r, String field) {
    switch (field) {
      case 'artists':
        return r.artistsCsv.toLowerCase();
      case 'genres':
        return r.genresCsv.toLowerCase();
      case 'descriptors':
        return r.descriptorsCsv.toLowerCase();
      case 'releaseDate':
        return (r.record.releaseDate ?? '').toLowerCase();
      case 'type':
        return (r.record.recordType ?? '').toLowerCase();
      case 'dateAdded':
        return (r.record.dateAdded ?? '').toLowerCase();
      case 'streaming':
        return r.streamingDisplayNames.join(', ').toLowerCase();
      case 'comments':
        return (r.record.comments ?? '').toLowerCase();
      default:
        return '';
    }
  }

  List<MapEntry<String, List<RecordDetails>>> get groupedRows {
    if (_groupedVersion == _viewVersion && _groupedCache != null) {
      return _groupedCache!;
    }
    final rows = sortedRows;
    if (groupByField == null) {
      _groupedCache = [MapEntry('', rows)];
      _groupedVersion = _viewVersion;
      return _groupedCache!;
    }
    final map = <String, List<RecordDetails>>{};
    for (final r in rows) {
      final keys = SearchQueryEngine.groupKeysFor(r, groupByField!);
      for (final key in keys) {
        map.putIfAbsent(key, () => []).add(r);
      }
    }
    var entries = map.entries.toList();
    if (groupOrderOverride.isNotEmpty) {
      entries.sort((a, b) =>
          (groupOrderOverride[a.key] ?? 999)
              .compareTo(groupOrderOverride[b.key] ?? 999));
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }
    _groupedCache = entries;
    _groupedVersion = _viewVersion;
    return _groupedCache!;
  }

  // ── Fuzzy Match (for edit modal chip recommendations) ─────────

  double fuzzyMatch(String queryText, String target) =>
      CsvUtils.calculateSimilarity(
          queryText.toLowerCase(), target.toLowerCase());

  // ── Edit / Delete ─────────────────────────────────────────────

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
      _splitBuckets();
      _applySearch();
      _bumpView();
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
      _splitBuckets();
      _applySearch();
      _bumpView();
      notifyListeners();
      return null;
    } catch (e) {
      return '$e';
    }
  }

  // ── Result Counts ─────────────────────────────────────────────

  int get totalRows => _filteredRecords.length;
}

class _ScoredRecord {
  final RecordDetails record;
  final double score;
  const _ScoredRecord(this.record, this.score);
}
