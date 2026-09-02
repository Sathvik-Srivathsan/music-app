import 'package:flutter/foundation.dart';
import 'package:music_collection/features/search/data/repositories/search_repository.dart';
import 'package:music_collection/features/statistics/data/repositories/audit_log_repository.dart';
import 'package:music_collection/features/statistics/data/repositories/statistics_repository.dart';
import 'package:music_collection/features/statistics/domain/statistics_engine.dart';
import 'package:music_collection/shared/models/audit_log.dart';
import 'package:music_collection/shared/models/record_details.dart';

/// The two modes the Statistics tab can show.
enum StatisticsSubTab { charts, log }

/// The seven collapsible chart sections of the Statistics tab.
enum StatisticsSection {
  overview,
  records,
  artists,
  genres,
  descriptors,
  streaming,
  relationships,
}

/// Owns state for the Statistics tab: fetched data, computed chart results,
/// the active sub-tab, and the collapsible section/chart expansion state.
///
/// Data is loaded on tab activation and via the manual refresh button (no
/// Supabase realtime). Chart results are computed once after each load and
/// cached so toggling a collapsible never re-aggregates.
class StatisticsProvider extends ChangeNotifier {
  final StatisticsRepository _repo;
  final AuditLogRepository _logRepo;

  StatisticsProvider({
    StatisticsRepository? repository,
    AuditLogRepository? auditLogRepository,
  })  : _repo = repository ?? StatisticsRepository(),
        _logRepo = auditLogRepository ?? AuditLogRepository();

  // ---- load state ----------------------------------------------------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadError;
  String? get loadError => _loadError;

  bool _loaded = false;
  bool get loaded => _loaded;

  // ---- raw data ------------------------------------------------------------
  List<RecordDetails> _rows = const [];
  List<MapEntry<int, int>> _genreEdges = const [];
  List<MapEntry<int, int>> _descriptorEdges = const [];

  // ---- computed results (cached after each load) --------------------------
  OverviewStats? _overview;
  OverviewStats? get overview => _overview;
  List<StatSlice> _statusSlices = const [];
  List<StatSlice> get statusSlices => _statusSlices;
  DecadeData _decadeData = const DecadeData(buckets: [], unknownCount: 0);
  DecadeData get decadeData => _decadeData;
  List<StatBar> _recordTypeBars = const [];
  List<StatBar> get recordTypeBars => _recordTypeBars;
  List<EntityCount> _topArtists = const [];
  List<EntityCount> get topArtists => _topArtists;
  List<EntityCount> _topGenres = const [];
  List<EntityCount> get topGenres => _topGenres;
  List<EntityCount> _topDescriptors = const [];
  List<EntityCount> get topDescriptors => _topDescriptors;
  StreamingPie? _streamingPie;
  StreamingPie? get streamingPie => _streamingPie;
  List<EntityCount> _relationships = const [];
  List<EntityCount> get relationships => _relationships;

  // ---- sub-tab -------------------------------------------------------------
  StatisticsSubTab _subTab = StatisticsSubTab.charts;
  StatisticsSubTab get subTab => _subTab;

  void setSubTab(StatisticsSubTab tab) {
    if (_subTab == tab) return;
    _subTab = tab;
    notifyListeners();
  }

  // ---- audit log viewer ----------------------------------------------------
  bool _logLoading = false;
  bool get logLoading => _logLoading;

  String? _logError;
  String? get logError => _logError;

  List<AuditLog> _logs = const [];
  List<AuditLog> get logs => _logs;

  int _logPage = 0;
  int get logPage => _logPage;

  bool _logHasMore = false;
  bool get logHasMore => _logHasMore;

  String _logActionFilter = '';
  String get logActionFilter => _logActionFilter;

  String _logTableFilter = '';
  String get logTableFilter => _logTableFilter;

  String _logSearch = '';
  String get logSearch => _logSearch;

  void setLogActionFilter(String value) {
    if (_logActionFilter == value) return;
    _logActionFilter = value;
    _logPage = 0;
    loadLogs();
  }

  void setLogTableFilter(String value) {
    if (_logTableFilter == value) return;
    _logTableFilter = value;
    _logPage = 0;
    loadLogs();
  }

  void setLogSearch(String value) {
    if (_logSearch == value) return;
    _logSearch = value;
    _logPage = 0;
    loadLogs();
  }

  void nextLogPage() {
    if (!_logHasMore || _logLoading) return;
    _logPage++;
    loadLogs();
  }

  void prevLogPage() {
    if (_logPage == 0 || _logLoading) return;
    _logPage--;
    loadLogs();
  }

  /// Jumps back to the first (newest) page and reloads.
  void goFirstLogPage() {
    if (_logPage == 0) {
      loadLogs();
      return;
    }
    _logPage = 0;
    loadLogs();
  }

  /// Reloads from the first page (used by the refresh button).
  Future<void> refreshLogs() async {
    _logPage = 0;
    await loadLogs();
  }

  /// Loads the current audit-log page (used by the Log viewer, which loads on
  /// tab visit and via the refresh button, matching the charts behaviour).
  Future<void> loadLogs() async {
    if (_logLoading) return;
    _logLoading = true;
    _logError = null;
    notifyListeners();
    try {
      final result = await _logRepo.fetchPage(
        action: _logActionFilter.isEmpty ? null : _logActionFilter,
        table: _logTableFilter.isEmpty ? null : _logTableFilter,
        search: _logSearch.isEmpty ? null : _logSearch,
        page: _logPage,
      );
      _logs = result.rows;
      _logHasMore = result.hasMore;
    } catch (e, st) {
      debugPrint('AUDIT LOG LOAD FAILED: $e\n$st');
      _logError = 'Failed to load the audit log: $e';
      _logs = const [];
      _logHasMore = false;
    } finally {
      _logLoading = false;
      notifyListeners();
    }
  }

  // ---- collapsible sections (subsection level) -----------------------------
  final Map<StatisticsSection, bool> _expandedSections = {
    StatisticsSection.overview: true,
  };

  bool isSectionExpanded(StatisticsSection section) =>
      _expandedSections[section] ?? false;

  void toggleSection(StatisticsSection section) {
    _expandedSections[section] = !(_expandedSections[section] ?? false);
    notifyListeners();
  }

  // ---- collapsible charts (individual chart level) -------------------------
  final Set<String> _expandedCharts = {};

  bool isChartExpanded(String chartId) => _expandedCharts.contains(chartId);

  void toggleChart(String chartId) {
    if (!_expandedCharts.add(chartId)) {
      _expandedCharts.remove(chartId);
    }
    notifyListeners();
  }

  /// Whether any part of this chart's section is currently expanded out at
  /// the subsection level (subsection-collapse un-renders all children
  /// regardless of their own chart toggles).
  bool sectionVisible(StatisticsSection section) => isSectionExpanded(section);

  // ---- data loading --------------------------------------------------------
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final result = await _repo.fetchAllData();
      _apply(result);
      _loaded = true;
    } catch (e, st) {
      debugPrint('STATISTICS LOAD FAILED: $e\n$st');
      _loadError = 'Failed to load statistics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _apply(FetchResult result) {
    _rows = result.rows;
    _genreEdges = result.genreEdges;
    _descriptorEdges = result.descriptorEdges;
    _overview = StatisticsEngine.computeOverview(_rows);
    _statusSlices = StatisticsEngine.statusSlices(_rows);
    _decadeData = StatisticsEngine.decadeData(_rows);
    _recordTypeBars = StatisticsEngine.recordTypeBars(_rows);
    _topArtists = StatisticsEngine.topArtists(_rows);
    _topGenres = StatisticsEngine.topGenres(_rows);
    _topDescriptors = StatisticsEngine.topDescriptors(_rows);
    _streamingPie = StatisticsEngine.streamingPie(_rows);
    _relationships = StatisticsEngine.relationshipSummaries(
      _rows,
      genreEdges: _genreEdges,
      descriptorEdges: _descriptorEdges,
    );
  }
}
