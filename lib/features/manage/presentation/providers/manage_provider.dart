import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/utils/chip_text_logic.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/core/utils/toast_utils.dart';
import 'package:music_collection/features/manage/data/repositories/manage_repository.dart';
import 'package:music_collection/features/manage/domain/models/tree_node.dart';
import 'package:music_collection/features/search/data/repositories/search_repository.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/record.dart';

enum ManageSubTab { artists, genres, descriptors, importExport }

enum ManageView { table, genreTree, descriptorTree }

enum ImportEntityType { fullDatabase, artists, genres, descriptors }

enum ImportPhase { idle, reading, validation, pass1, rectification, pass2, summary }

enum EntitySortField { name, refCount, childrenCount, totalRefCount }

class ParentNotFoundItem {
  final int rowCsvIndex;
  final String childName;
  final String parentName;
  bool skipped;

  ParentNotFoundItem({
    required this.rowCsvIndex,
    required this.childName,
    required this.parentName,
    this.skipped = false,
  });
}

class ArtistMismatchItem {
  final int rowCsvIndex;
  final String recordName;
  final String csvArtistName;
  final List<String> allCsvArtists;
  bool skipped;

  ArtistMismatchItem({
    required this.rowCsvIndex,
    required this.recordName,
    required this.csvArtistName,
    required this.allCsvArtists,
    this.skipped = false,
  });
}

class GenreMismatchItem {
  final int rowCsvIndex;
  final String recordName;
  final List<String> invalidGenres;
  bool skipped;

  GenreMismatchItem({
    required this.rowCsvIndex,
    required this.recordName,
    required this.invalidGenres,
    this.skipped = false,
  });
}

class DescMismatchItem {
  final int rowCsvIndex;
  final String recordName;
  final List<String> invalidDescriptors;
  bool skipped;

  DescMismatchItem({
    required this.rowCsvIndex,
    required this.recordName,
    required this.invalidDescriptors,
    this.skipped = false,
  });
}

class StreamingWarningItem {
  final int rowCsvIndex;
  final String recordName;
  final List<String> unrecognizedNames;
  bool skipped;

  StreamingWarningItem({
    required this.rowCsvIndex,
    required this.recordName,
    required this.unrecognizedNames,
    this.skipped = false,
  });
}

class SeparatorWarningItem {
  final int rowCsvIndex;
  final String recordName;
  final String fieldName;
  final String rawValue;
  bool skipped;

  SeparatorWarningItem({
    required this.rowCsvIndex,
    required this.recordName,
    required this.fieldName,
    required this.rawValue,
    this.skipped = false,
  });
}

class DateFormatWarningItem {
  final int rowCsvIndex;
  final String recordName;
  final String fieldName;
  final String rawValue;
  bool skipped;

  DateFormatWarningItem({
    required this.rowCsvIndex,
    required this.recordName,
    required this.fieldName,
    required this.rawValue,
    this.skipped = false,
  });
}

class RecordTypeInvalidItem {
  final int rowCsvIndex;
  final String recordName;
  final String rawValue;
  bool skipped;

  RecordTypeInvalidItem({
    required this.rowCsvIndex,
    required this.recordName,
    required this.rawValue,
    this.skipped = false,
  });
}

class ParentCellParseResult {
  final List<String> tokens;
  final Set<String> separators;
  final bool mixed;

  bool get empty => tokens.isEmpty;

  const ParentCellParseResult({
    required this.tokens,
    required this.separators,
    required this.mixed,
  });
}

class ImportSummaryRecord {
  final String recordName;
  final String artists;
  const ImportSummaryRecord({required this.recordName, required this.artists});
}

class ImportSummarySkipped {
  final String recordName;
  final String reason;
  const ImportSummarySkipped({required this.recordName, required this.reason});
}

class ManageProvider extends ChangeNotifier {
  final ManageRepository _repo = ManageRepository();
  final SearchRepository _searchRepo = SearchRepository();

  ManageSubTab _subTab = ManageSubTab.artists;
  ManageSubTab get subTab => _subTab;

  List<EntityWithRefCount<Artist>> _artists = [];
  List<EntityWithRefCount<Genre>> _genres = [];
  List<EntityWithRefCount<Descriptor>> _descriptors = [];

  List<EntityWithRefCount<Artist>> get artists => _filtered(_artists);
  List<EntityWithRefCount<Genre>> get genres => _filtered(_genres);
  List<EntityWithRefCount<Descriptor>> get descriptors =>
      _filtered(_descriptors);

  List<EntityWithRefCount<Artist>> get rawArtists => _artists;
  List<EntityWithRefCount<Genre>> get rawGenres => _genres;
  List<EntityWithRefCount<Descriptor>> get rawDescriptors => _descriptors;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  EntitySortField _sortField = EntitySortField.name;
  EntitySortField get sortField => _sortField;

  bool _sortAsc = true;
  bool get sortAsc => _sortAsc;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadError;
  String? get loadError => _loadError;

  // --- View state (table vs tree) ---

  ManageView _view = ManageView.table;
  ManageView get view => _view;

  List<TreeNode>? _genreTree;
  List<TreeNode>? get genreTree => _genreTree;
  List<TreeNode>? _descriptorTree;
  List<TreeNode>? get descriptorTree => _descriptorTree;

  Set<int> _expandedGenreIds = {};
  Set<int> get expandedGenreIds => _expandedGenreIds;
  Set<int> _expandedDescriptorIds = {};
  Set<int> get expandedDescriptorIds => _expandedDescriptorIds;

  bool _treeLoading = false;
  bool get treeLoading => _treeLoading;
  String? _treeError;
  String? get treeError => _treeError;

  // --- Import state ---

  ImportEntityType? _importEntityType;
  ImportEntityType? get importEntityType => _importEntityType;

  ImportEntityType? _importEntityTypeSelection;
  ImportEntityType? get importEntityTypeSelection => _importEntityTypeSelection;

  List<List<dynamic>>? _importRows;
  List<List<dynamic>>? get importRows => _importRows;

  List<String> _importHeaders = [];
  List<String> get importHeaders => _importHeaders;

  String? _importFileName;
  String? get importFileName => _importFileName;

  int _importTotal = 0;
  int get importTotal => _importTotal;
  int _importValid = 0;
  int get importValid => _importValid;
  int _importEmptyNames = 0;
  int get importEmptyNames => _importEmptyNames;
  int _importDuplicatesInFile = 0;
  int get importDuplicatesInFile => _importDuplicatesInFile;
  int _importDuplicatesVsDb = 0;
  int get importDuplicatesVsDb => _importDuplicatesVsDb;
  int _importBrokenParents = 0;
  int get importBrokenParents => _importBrokenParents;

  bool _importing = false;
  bool get importing => _importing;
  String? _importError;
  String? get importError => _importError;
  String? _importSuccess;
  String? get importSuccess => _importSuccess;

  ImportPhase _importPhase = ImportPhase.idle;
  ImportPhase get importPhase => _importPhase;

  List<ImportSummaryRecord> _importedRecords = [];
  List<ImportSummaryRecord> get importedRecords => _importedRecords;

  List<ImportSummarySkipped> _skippedRecords = [];
  List<ImportSummarySkipped> get skippedRecords => _skippedRecords;

  // --- Import two-pass state ---

  List<List<dynamic>>? _importPass1Rows;
  List<List<dynamic>>? get importPass1Rows => _importPass1Rows;

  Map<int, List<dynamic>> _importModifiedRows = {};
  Map<int, List<dynamic>> get importModifiedRows => _importModifiedRows;

  Set<int> _skippedTupleRowIndexes = {};
  Set<int> get skippedTupleRowIndexes => _skippedTupleRowIndexes;

  List<String> _importPass1Headers = [];
  List<String> get importPass1Headers => _importPass1Headers;

  // Warning queues for standalone genres/descriptors
  List<ParentNotFoundItem> _parentNotFoundQueue = [];
  List<ParentNotFoundItem> get parentNotFoundQueue => _parentNotFoundQueue;

  int _parentNotFoundIndex = 0;
  int get parentNotFoundIndex => _parentNotFoundIndex;
  int get parentNotFoundTotal => _parentNotFoundQueue.length;

  // --- Full Database Import queues ---

  List<ArtistMismatchItem> _artistMismatchQueue = [];
  List<ArtistMismatchItem> get artistMismatchQueue => _artistMismatchQueue;
  int _artistMismatchIndex = 0;
  int get artistMismatchIndex => _artistMismatchIndex;

  List<GenreMismatchItem> _genreMismatchQueue = [];
  List<GenreMismatchItem> get genreMismatchQueue => _genreMismatchQueue;
  int _genreMismatchIndex = 0;
  int get genreMismatchIndex => _genreMismatchIndex;

  List<DescMismatchItem> _descMismatchQueue = [];
  List<DescMismatchItem> get descMismatchQueue => _descMismatchQueue;
  int _descMismatchIndex = 0;
  int get descMismatchIndex => _descMismatchIndex;

  List<StreamingWarningItem> _streamingWarningQueue = [];
  List<StreamingWarningItem> get streamingWarningQueue => _streamingWarningQueue;
  int _streamingWarningIndex = 0;
  int get streamingWarningIndex => _streamingWarningIndex;

  List<SeparatorWarningItem> _separatorWarningQueue = [];
  List<SeparatorWarningItem> get separatorWarningQueue => _separatorWarningQueue;
  int _separatorWarningIndex = 0;
  int get separatorWarningIndex => _separatorWarningIndex;

  List<DateFormatWarningItem> _dateFormatWarningQueue = [];
  List<DateFormatWarningItem> get dateFormatWarningQueue => _dateFormatWarningQueue;
  int _dateFormatWarningIndex = 0;
  int get dateFormatWarningIndex => _dateFormatWarningIndex;

  List<RecordTypeInvalidItem> _recordTypeInvalidQueue = [];
  List<RecordTypeInvalidItem> get recordTypeInvalidQueue => _recordTypeInvalidQueue;
  int _recordTypeInvalidIndex = 0;
  int get recordTypeInvalidIndex => _recordTypeInvalidIndex;

  int _statusWarningCount = 0;
  int get statusWarningCount => _statusWarningCount;

  int _extraUrlRows = 0;
  int get extraUrlRows => _extraUrlRows;

  int _recordSkipCount = 0;
  int get recordSkipCount => _recordSkipCount;

  Set<int> _validatedSkipRowIndexes = {};
  Set<int> get validatedSkipRowIndexes => _validatedSkipRowIndexes;

  List<ImportSummarySkipped> _validatedSkippedRecords = [];
  List<ImportSummarySkipped> get validatedSkippedRecords => _validatedSkippedRecords;

  Set<String> _existingRecordNorms = {};
  bool _existingRecordNormsLoaded = false;
  bool _existingRecordNormsOverride = false;

  bool _dateAddedViolation = false;
  bool get dateAddedViolation => _dateAddedViolation;

  bool _dateAddedResolved = false;
  bool get dateAddedResolved => _dateAddedResolved;

  bool _parentColumnMissing = false;
  bool get parentColumnMissing => _parentColumnMissing;

  bool _parentColumnGatePending = false;
  bool get parentColumnGate => _parentColumnGatePending;

  Set<String> _importExistingDbNorms = {};

  bool get allRectified {
    if (_recordTypeInvalidIndex < _recordTypeInvalidQueue.length) return false;
    if (_artistMismatchIndex < _artistMismatchQueue.length) return false;
    if (_streamingWarningIndex < _streamingWarningQueue.length) return false;
    if (_separatorWarningIndex < _separatorWarningQueue.length) return false;
    if (_dateFormatWarningIndex < _dateFormatWarningQueue.length) return false;
    if (_genreMismatchIndex < _genreMismatchQueue.length) return false;
    if (_descMismatchIndex < _descMismatchQueue.length) return false;
    if (_parentNotFoundIndex < _parentNotFoundQueue.length) return false;
    return true;
  }

  String? get activeWarningQueue {
    if (_recordTypeInvalidIndex < _recordTypeInvalidQueue.length) {
      return 'recordTypeInvalid';
    }
    if (_artistMismatchIndex < _artistMismatchQueue.length) return 'artistMismatch';
    if (_streamingWarningIndex < _streamingWarningQueue.length) return 'streaming';
    if (_separatorWarningIndex < _separatorWarningQueue.length) return 'separator';
    if (_dateFormatWarningIndex < _dateFormatWarningQueue.length) return 'dateFormat';
    if (_genreMismatchIndex < _genreMismatchQueue.length) return 'genreMismatch';
    if (_descMismatchIndex < _descMismatchQueue.length) return 'descMismatch';
    if (_parentNotFoundIndex < _parentNotFoundQueue.length) return 'parentNotFound';
    return null;
  }

  // --- Sub-tab ---

  void setSubTab(ManageSubTab tab) {
    _subTab = tab;
    _searchQuery = '';
    if (_view != ManageView.table) {
      _view = ManageView.table;
      _genreTree = null;
      _descriptorTree = null;
    }
    notifyListeners();
  }

  // --- Search ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- Sort ---

  void setSortField(EntitySortField field) {
    if (_sortField == field) {
      _sortAsc = !_sortAsc;
    } else {
      _sortField = field;
      _sortAsc = true;
    }
    notifyListeners();
  }

  // --- Tree view ---

  void openGenreTree() {
    _view = ManageView.genreTree;
    _expandedGenreIds = {};
    notifyListeners();
    _loadGenreTree();
  }

  void openDescriptorTree() {
    _view = ManageView.descriptorTree;
    _expandedDescriptorIds = {};
    notifyListeners();
    _loadDescriptorTree();
  }

  void backToTable() {
    _view = ManageView.table;
    _genreTree = null;
    _descriptorTree = null;
    _treeError = null;
    notifyListeners();
  }

  void toggleGenreNode(int id) {
    if (_expandedGenreIds.contains(id)) {
      _expandedGenreIds.remove(id);
    } else {
      _expandedGenreIds.add(id);
    }
    notifyListeners();
  }

  void toggleDescriptorNode(int id) {
    if (_expandedDescriptorIds.contains(id)) {
      _expandedDescriptorIds.remove(id);
    } else {
      _expandedDescriptorIds.add(id);
    }
    notifyListeners();
  }

  void expandAllGenreNodes() {
    _expandedGenreIds = _collectAllIds(_genreTree);
    notifyListeners();
  }

  void collapseAllGenreNodes() {
    _expandedGenreIds = {};
    notifyListeners();
  }

  void expandAllDescriptorNodes() {
    _expandedDescriptorIds = _collectAllIds(_descriptorTree);
    notifyListeners();
  }

  void collapseAllDescriptorNodes() {
    _expandedDescriptorIds = {};
    notifyListeners();
  }

  Set<int> _collectAllIds(List<TreeNode>? nodes) {
    final ids = <int>{};
    if (nodes == null) return ids;
    void walk(List<TreeNode> list) {
      for (final n in list) {
        if (n.hasChildren) {
          ids.add(n.id);
          walk(n.children);
        }
      }
    }
    walk(nodes);
    return ids;
  }

  Future<void> _loadGenreTree() async {
    _treeLoading = true;
    _treeError = null;
    notifyListeners();
    try {
      final edges = await _repo.fetchGenreHierarchyEdges();
      _genreTree = _buildTree(_genres, edges);
    } catch (e) {
      _treeError = 'Failed to load genre tree: $e';
    } finally {
      _treeLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDescriptorTree() async {
    _treeLoading = true;
    _treeError = null;
    notifyListeners();
    try {
      final edges = await _repo.fetchDescriptorHierarchyEdges();
      _descriptorTree = _buildTree(_descriptors, edges);
    } catch (e) {
      _treeError = 'Failed to load descriptor tree: $e';
    } finally {
      _treeLoading = false;
      notifyListeners();
    }
  }

  List<TreeNode> _buildTree<T>(
    List<EntityWithRefCount<T>> entities,
    List<(int parentId, int childId)> edges,
  ) {
    final nameById = <int, String>{};
    final descendantCountById = <int, int>{};
    for (final e in entities) {
      final id = _entityId(e.entity);
      if (id != null) {
        nameById[id] = _entityName(e.entity);
        descendantCountById[id] = e.childrenCount;
      }
    }

    final childrenOf = <int, List<int>>{};
    final childSet = <int>{};
    for (final (parent, child) in edges) {
      (childrenOf[parent] ??= []).add(child);
      childSet.add(child);
    }

    for (final list in childrenOf.values) {
      list.sort((a, b) {
        final na = nameById[a] ?? '';
        final nb = nameById[b] ?? '';
        return na.toLowerCase().compareTo(nb.toLowerCase());
      });
    }

    final nodeCache = <int, TreeNode>{};
    TreeNode buildNode(int id) {
      return nodeCache.putIfAbsent(id, () {
        final children = (childrenOf[id] ?? []).map(buildNode).toList();
        return TreeNode(
          id: id,
          name: nameById[id] ?? 'Unknown ($id)',
          children: children,
          descendantCount: descendantCountById[id] ?? 0,
        );
      });
    }

    final roots = nameById.keys
        .where((id) => !childSet.contains(id))
        .map(buildNode)
        .toList()
      ..sort((a, b) => b.descendantCount.compareTo(a.descendantCount));

    return roots;
  }

  int? _entityId(dynamic entity) {
    if (entity is Artist) return entity.artistId;
    if (entity is Genre) return entity.genreId;
    if (entity is Descriptor) return entity.descriptorId;
    return null;
  }

  // --- Export ---

  String? _exportCsv;

  String? get exportCsv => _exportCsv;

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> executeExport() async {
    final type = _importEntityType;
    if (type == null) return;
    switch (type) {
      case ImportEntityType.artists:
        _exportCsv = _exportArtistsCsv();
        break;
      case ImportEntityType.genres:
        _exportCsv = await _exportGenresCsv();
        break;
      case ImportEntityType.descriptors:
        _exportCsv = await _exportDescriptorsCsv();
        break;
      case ImportEntityType.fullDatabase:
        _exportCsv = await _exportFullDatabaseCsv();
        break;
    }
    if (_exportCsv != null) {
      await _repo.logAction(
        action: 'export',
        tableName: 'csv',
        details: {'type': type.name},
      );
      ToastUtils.showSuccess('Downloaded ${type.name} export.');
    }
    notifyListeners();
  }

  void clearExport() {
    _exportCsv = null;
    notifyListeners();
  }

  String _exportArtistsCsv() {
    final rows = <List<String>>[];
    rows.add(['name']);
    for (final e in _artists) {
      rows.add([_csvEscape(e.entity.artistName)]);
    }
    return Csv(addBom: true).encode(rows);
  }

  Future<String> _exportGenresCsv() async {
    final edges = await _repo.fetchGenreHierarchyEdges();
    final nameById = <int, String>{};
    for (final e in _genres) {
      nameById[e.entity.genreId!] = e.entity.genreName;
    }
    final childToParent = <String, String>{};
    for (final (parentId, childId) in edges) {
      final parentName = nameById[parentId];
      final childName = nameById[childId];
      if (parentName != null && childName != null) {
        childToParent[childName] = parentName;
      }
    }
    final rows = <List<String>>[];
    rows.add(['name', 'parent']);
    for (final e in _genres) {
      final name = e.entity.genreName;
      final parent = childToParent[name] ?? '';
      rows.add([_csvEscape(name), _csvEscape(parent)]);
    }
    return Csv(addBom: true).encode(rows);
  }

  Future<String> _exportDescriptorsCsv() async {
    final edges = await _repo.fetchDescriptorHierarchyEdges();
    final nameById = <int, String>{};
    for (final e in _descriptors) {
      nameById[e.entity.descriptorId!] = e.entity.descriptorName;
    }
    final childToParent = <String, String>{};
    for (final (parentId, childId) in edges) {
      final parentName = nameById[parentId];
      final childName = nameById[childId];
      if (parentName != null && childName != null) {
        childToParent[childName] = parentName;
      }
    }
    final rows = <List<String>>[];
    rows.add(['name', 'parent']);
    for (final e in _descriptors) {
      final name = e.entity.descriptorName;
      final parent = childToParent[name] ?? '';
      rows.add([_csvEscape(name), _csvEscape(parent)]);
    }
    return Csv(addBom: true).encode(rows);
  }

  Future<String> _exportFullDatabaseCsv() async {
    final result = await _searchRepo.fetchAllRecordDetails();
    final records = result.rows;

    final rows = <List<String>>[];
    rows.add([
      'record_name',
      'artists',
      'genres',
      'descriptors',
      'release_date',
      'type',
      'streaming',
      'URL',
      'comments',
      'status',
    ]);

    for (final rd in records) {
      final streamingNames = <String>[];
      final streamingUrls = <String>[];
      for (final s in rd.streaming) {
        final display = s.serviceName == 'SoulSeekQT'
            ? 'SoulSeekQT (SSQT)'
            : s.serviceName;
        streamingNames.add(display);
        streamingUrls.add(s.serviceUrl);
      }

      rows.add([
        _csvEscape(rd.record.recordName),
        _csvEscape(rd.artistsCsv),
        _csvEscape(rd.genresCsv),
        _csvEscape(rd.descriptorsCsv),
        _csvEscape(rd.record.releaseDate ?? ''),
        _csvEscape(rd.record.recordType ?? ''),
        _csvEscape(streamingNames.join(', ')),
        _csvEscape(streamingUrls.join(', ')),
        _csvEscape(rd.record.comments ?? ''),
        rd.record.status ? 'Finished' : 'Active',
      ]);
    }

    return Csv(addBom: true).encode(rows);
  }

  // --- Import ---

  void setImportEntityType(ImportEntityType? type) {
    _importEntityType = type;
    _clearImportData();
    notifyListeners();
  }

  void setImportEntityTypeSelection(ImportEntityType? type) {
    _importEntityTypeSelection = type;
    _clearImportData();
    notifyListeners();
  }

  void setImportError(String message) {
    _importError = message;
    _importSuccess = null;
    notifyListeners();
  }

  void beginImportRead() {
    _importError = null;
    _importSuccess = null;
    _importPhase = ImportPhase.reading;
    notifyListeners();
  }

  Future<void> loadImportFile(String csvString, String fileName) async {
    _importError = null;
    _importSuccess = null;
    _importFileName = fileName;
    if (csvString.startsWith('\uFEFF')) {
      csvString = csvString.substring(1);
    }

    try {
      final rows = Csv(
        dynamicTyping: true,
        fieldDelimiter: ',',
        quoteCharacter: '"',
        autoDetect: false,
      ).decode(csvString);
      if (rows.isEmpty) {
        _importError = 'CSV file is empty.';
        _importPhase = ImportPhase.idle;
        notifyListeners();
        return;
      }

      _importHeaders =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      _importRows = rows;

      _importPass1Headers = List<String>.from(_importHeaders);
      _importPass1Rows = rows;
      _importModifiedRows = {};
      _skippedTupleRowIndexes = {};

      if (_importEntityTypeSelection == ImportEntityType.fullDatabase) {
        await _validateFullDatabaseImport();
      } else {
        _validateImport();
      }
    } catch (e) {
      _importError = 'Failed to parse CSV: $e';
      _importPhase = ImportPhase.idle;
    }
    if (_importError == null) {
      _importPhase = ImportPhase.validation;
    }
    notifyListeners();
  }

  // --- Import validation helpers ---

  static int _detectColumn(List<String> headers, List<String> candidates) {
    for (final c in candidates) {
      final idx = headers.indexOf(c);
      if (idx >= 0) return idx;
    }
    return -1;
  }

  void _validateImport() {
    _importTotal = 0;
    _importValid = 0;
    _importEmptyNames = 0;
    _importDuplicatesInFile = 0;
    _importDuplicatesVsDb = 0;
    _importBrokenParents = 0;

    final type = _importEntityTypeSelection;
    final rows = _importRows;
    if (type == null || rows == null || rows.length <= 1) {
      _importTotal = 0;
      return;
    }

    final dataRows = rows.sublist(1);
    _importTotal = dataRows.length;

    if (type == ImportEntityType.artists || type == ImportEntityType.fullDatabase) {
      _validateArtistRows(dataRows);
    }
    if (type == ImportEntityType.genres || type == ImportEntityType.fullDatabase) {
      _validateGenreRows(dataRows);
    }
    if (type == ImportEntityType.descriptors || type == ImportEntityType.fullDatabase) {
      _validateDescriptorRows(dataRows);
    }
  }

  void _validateArtistRows(List<List<dynamic>> dataRows) {
    final nameIdx = _detectColumn(_importHeaders, const [
      'name',
      'artist',
      'artists',
      'artist_name',
      'artistname',
      'artist name',
    ]);
    final typeIdx = _importHeaders.indexOf('type');
    final seen = <String>{};
    final dbNames = _artists.map((e) => e.entity.artistName.toLowerCase()).toSet();

    for (final row in dataRows) {
      if (typeIdx >= 0 && typeIdx < row.length) {
        final t = row[typeIdx].toString().trim().toLowerCase();
        if (t != 'artist' && t.isNotEmpty) continue;
      }
      final name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (name.isEmpty) {
        _importEmptyNames++;
        continue;
      }
      final lower = name.toLowerCase();
      if (seen.contains(lower)) {
        _importDuplicatesInFile++;
        continue;
      }
      seen.add(lower);
      if (dbNames.contains(lower)) {
        _importDuplicatesVsDb++;
      } else {
        _importValid++;
      }
    }
  }

  void _validateGenreRows(List<List<dynamic>> dataRows) {
    final nameIdx = _detectColumn(_importHeaders, const [
      'name',
      'genre',
      'genres',
      'genre_name',
      'genrename',
      'genre name',
    ]);
    final parentIdx = _detectColumn(_importHeaders, const [
      'parent',
      'parent_genre',
      'parentgenre',
      'parent genre',
    ]);
    _parentColumnMissing = parentIdx < 0;
    final typeIdx = _importHeaders.indexOf('type');
    final seen = <String>{};
    final dbNames = _genres.map((e) => e.entity.genreName.toLowerCase()).toSet();
    final allNames = <String>{...dbNames};
    final newNames = <String>{};

    for (final row in dataRows) {
      if (typeIdx >= 0 && typeIdx < row.length) {
        final t = row[typeIdx].toString().trim().toLowerCase();
        if (t != 'genre' && t.isNotEmpty) continue;
      }
      final name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (name.isEmpty) {
        _importEmptyNames++;
        continue;
      }
      final lower = name.toLowerCase();
      if (seen.contains(lower)) {
        _importDuplicatesInFile++;
        continue;
      }
      seen.add(lower);
      if (dbNames.contains(lower)) {
        _importDuplicatesVsDb++;
      } else {
        newNames.add(lower);
        _importValid++;
      }

      if (parentIdx >= 0 && parentIdx < row.length) {
        final parent = row[parentIdx].toString().trim();
        if (parent.isNotEmpty) {
          final parentLower = parent.toLowerCase();
          if (!allNames.contains(parentLower) && !newNames.contains(parentLower)) {
            _importBrokenParents++;
          }
        }
      }
    }
  }

  void _validateDescriptorRows(List<List<dynamic>> dataRows) {
    final nameIdx = _detectColumn(_importHeaders, const [
      'name',
      'descriptor',
      'descriptors',
      'descriptor_name',
      'descriptorname',
      'descriptor name',
    ]);
    final parentIdx = _detectColumn(_importHeaders, const [
      'parent',
      'parent_descriptor',
      'parentdescriptor',
      'parent descriptor',
    ]);
    _parentColumnMissing = parentIdx < 0;
    final typeIdx = _importHeaders.indexOf('type');
    final seen = <String>{};
    final dbNames =
        _descriptors.map((e) => e.entity.descriptorName.toLowerCase()).toSet();
    final allNames = <String>{...dbNames};
    final newNames = <String>{};

    for (final row in dataRows) {
      if (typeIdx >= 0 && typeIdx < row.length) {
        final t = row[typeIdx].toString().trim().toLowerCase();
        if (t != 'descriptor' && t.isNotEmpty) continue;
      }
      final name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (name.isEmpty) {
        _importEmptyNames++;
        continue;
      }
      final lower = name.toLowerCase();
      if (seen.contains(lower)) {
        _importDuplicatesInFile++;
        continue;
      }
      seen.add(lower);
      if (dbNames.contains(lower)) {
        _importDuplicatesVsDb++;
      } else {
        newNames.add(lower);
        _importValid++;
      }

      if (parentIdx >= 0 && parentIdx < row.length) {
        final parent = row[parentIdx].toString().trim();
        if (parent.isNotEmpty) {
          final parentLower = parent.toLowerCase();
          if (!allNames.contains(parentLower) && !newNames.contains(parentLower)) {
            _importBrokenParents++;
          }
        }
      }
    }
  }

  // --- Full Database Import: Validation ---

  static final _validSeparators = RegExp(r',\s*|\|\s*');

  List<String> _splitWithSeparators(String cell) {
    return cell
        .split(_validSeparators)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @visibleForTesting
  static ParentCellParseResult parseParentCell(String cell) {
    final raw = cell.trim();
    final separators = <String>{};
    for (final ch in raw.split('')) {
      if (ch == ',' || ch == '|') separators.add(ch);
    }
    final tokens = <String>[];
    for (final part in raw.split(_validSeparators)) {
      final t = part.trim();
      if (t.isEmpty) continue;
      final norm = t.toLowerCase();
      if (!tokens.any((e) => e.toLowerCase() == norm)) {
        tokens.add(t);
      }
    }
    return ParentCellParseResult(
      tokens: tokens,
      separators: separators,
      mixed: separators.length >= 2,
    );
  }

  @visibleForTesting
  static String replaceParentToken(
      String cell, String missingTokenNorm, String replacement) {
    final parsed = parseParentCell(cell);
    final newTokens = <String>[];
    var replaced = false;
    for (final t in parsed.tokens) {
      if (!replaced &&
          ChipTextLogic.normalizeForMatch(t) == missingTokenNorm) {
        newTokens.add(replacement);
        replaced = true;
      } else {
        newTokens.add(t);
      }
    }
    if (!replaced) newTokens.add(replacement);
    return newTokens.isEmpty ? replacement : newTokens.join(', ');
  }

  @visibleForTesting
  static List<(int, int)> resolveHierarchyEdges({
    required List<String> insertedNames,
    required Map<int, List<String>> parentTokens,
    required Map<String, int> allNameToId,
  }) {
    final edges = <(int, int)>[];
    for (final entry in parentTokens.entries) {
      final childName =
          entry.key < insertedNames.length ? insertedNames[entry.key] : null;
      if (childName == null) continue;
      final childId = allNameToId[childName.toLowerCase()];
      if (childId == null) continue;
      for (final token in entry.value) {
        final parentId = allNameToId[token.toLowerCase()];
        if (parentId != null && parentId != childId) {
          edges.add((parentId, childId));
        }
      }
    }
    return edges;
  }

  int _importNameColumnIndex() {
    final type = _importEntityTypeSelection;
    return _detectColumn(_importPass1Headers, [
      'name',
      'record_name', 'recordname', 'record name',
      if (type == ImportEntityType.genres)
        ...['genre', 'genres', 'genre_name', 'genrename', 'genre name'],
      if (type == ImportEntityType.descriptors)
        ...['descriptor', 'descriptors', 'descriptor_name', 'descriptorname', 'descriptor name'],
    ]);
  }

  /// Silently skipped rows (blank name / dup-in-file / already-in-DB) get
  /// their record_name blanked here so pass 2 never writes them.
  void _skipRow(int rowIdx) {
    final rows = _importPass1Rows;
    if (rows == null) return;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) row[nameIdx] = '';
    _importModifiedRows[rowIdx] = row;
  }

  String? _matchRecordType(String value) {
    final norm = ChipTextLogic.normalizeForMatch(value);
    if (norm.isEmpty) return null;
    for (final allowed in AppConstants.recordTypes) {
      if (ChipTextLogic.normalizeForMatch(allowed) == norm) return allowed;
    }
    return null;
  }

  @visibleForTesting
  void debugSetExistingRecordNorms(Set<String> norms) {
    _existingRecordNormsOverride = true;
    _existingRecordNorms =
        norms.map(ChipTextLogic.normalizeForMatch).toSet();
    _existingRecordNormsLoaded = true;
  }

  static final _dateFormats = [
    RegExp(r'^\d{4}$'),
    RegExp(r'^\d{4}-\d{2}$'),
    RegExp(r'^\d{4}-\d{2}-\d{2}$'),
    RegExp(r'^\d{2}-\d{2}-\d{4}$'),
    RegExp(r'^\d{2}-\d{4}$'),
    RegExp(r'^\d{4}/\d{2}$'),
    RegExp(r'^\d{4}/\d{2}/\d{2}$'),
    RegExp(r'^\d{2}/\d{2}/\d{4}$'),
    RegExp(r'^\d{2}/\d{4}$'),
  ];

  bool _isValidDateFormat(String value) {
    return _dateFormats.any((r) => r.hasMatch(value.trim()));
  }

  static final _acceptedStreamingDbValues = [
    'spotify',
    'youtube',
    'soundcloud',
    'bandcamp',
    'soulseekqt',
  ];

  String? _matchStreamingName(String name) {
    final norm = ChipTextLogic.normalizeForMatch(name);
    if (norm.isEmpty) return null;
    for (final dbVal in _acceptedStreamingDbValues) {
      if (ChipTextLogic.normalizeForMatch(dbVal) == norm) {
        return AppConstants.streamingToDisplay(dbVal);
      }
    }
    return null;
  }

  Future<void> _validateFullDatabaseImport() async {
    _importTotal = 0;
    _importValid = 0;
    _importEmptyNames = 0;
    _importDuplicatesInFile = 0;
    _importDuplicatesVsDb = 0;
    _importBrokenParents = 0;
    _artistMismatchQueue = [];
    _artistMismatchIndex = 0;
    _genreMismatchQueue = [];
    _genreMismatchIndex = 0;
    _descMismatchQueue = [];
    _descMismatchIndex = 0;
    _streamingWarningQueue = [];
    _streamingWarningIndex = 0;
    _separatorWarningQueue = [];
    _separatorWarningIndex = 0;
    _dateFormatWarningQueue = [];
    _dateFormatWarningIndex = 0;
    _recordTypeInvalidQueue = [];
    _recordTypeInvalidIndex = 0;
    _statusWarningCount = 0;
    _recordSkipCount = 0;
    _extraUrlRows = 0;
    _validatedSkipRowIndexes = {};
    _validatedSkippedRecords = [];
    _dateAddedViolation = false;

    final rows = _importRows;
    if (rows == null || rows.length <= 1) {
      _importTotal = 0;
      return;
    }

    final dataRows = rows.sublist(1);
    _importTotal = dataRows.length;

    // Detect column indices
    final nameIdx = _detectColumn(_importHeaders, const [
      'record_name', 'recordname', 'record name', 'name',
    ]);
    final artistsIdx = _detectColumn(_importHeaders, const [
      'artists', 'artist', 'artist_name', 'artistname', 'artist name',
    ]);
    final genresIdx = _detectColumn(_importHeaders, const [
      'genres', 'genre', 'genre_name', 'genrename', 'genre name',
    ]);
    final descsIdx = _detectColumn(_importHeaders, const [
      'descriptors', 'descriptor', 'descriptor_name', 'descriptorname', 'descriptor name',
    ]);
    final releaseDateIdx = _detectColumn(_importHeaders, const [
      'release_date', 'releasedate', 'release date', 'date',
    ]);
    final streamingIdx = _detectColumn(_importHeaders, const [
      'streaming', 'streamings', 'streaming_service', 'streamingservice',
    ]);
    final urlIdx = _detectColumn(_importHeaders, const [
      'url', 'urls', 'streaming_url', 'streamingurl', 'streaming url',
    ]);
    final typeIdx = _detectColumn(_importHeaders, const ['type']);
    final statusIdx = _detectColumn(_importHeaders, const [
      'status',
    ]);

    // Build DB lookup sets (type-2 normalized)
    final dbArtistNorms = _artists
        .map((e) => ChipTextLogic.normalizeForMatch(e.entity.artistName))
        .toSet();
    final dbGenreNorms = _genres
        .map((e) => ChipTextLogic.normalizeForMatch(e.entity.genreName))
        .toSet();
    final dbDescNorms = _descriptors
        .map((e) => ChipTextLogic.normalizeForMatch(e.entity.descriptorName))
        .toSet();
    final dbRecordNorms = <String>{};

    // Existing DB record names: cached so the double validation (load +
    // start) doesn't re-query; a debug override keeps tests DB-free.
    if (!_existingRecordNormsLoaded) {
      final existingNames = await _repo.fetchRecordNames();
      _existingRecordNorms =
          existingNames.map(ChipTextLogic.normalizeForMatch).toSet();
      _existingRecordNormsLoaded = true;
    }
    final existingDbNorms = _existingRecordNorms;

    for (var i = 0; i < dataRows.length; i++) {
      if (i % 50 == 0) await Future.delayed(Duration.zero);
      final row = dataRows[i];

      // 1. Record name check
      final recordName = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      var skipReason = '';
      if (recordName.isEmpty) {
        skipReason = 'Empty name';
      } else {
        final recordNorm = ChipTextLogic.normalizeForMatch(recordName);
        if (dbRecordNorms.contains(recordNorm)) {
          skipReason = 'Duplicate within the file';
        } else if (existingDbNorms.contains(recordNorm)) {
          skipReason = 'Already in the database';
        } else {
          dbRecordNorms.add(recordNorm);
        }
      }
      if (skipReason.isNotEmpty) {
        _recordSkipCount++;
        _validatedSkipRowIndexes.add(i);
        _validatedSkippedRecords.add(ImportSummarySkipped(
          recordName: recordName.isEmpty ? '(empty)' : recordName,
          reason: skipReason,
        ));
        _skipRow(i);
        continue;
      }

      // Valid record — count it
      _importValid++;

      // 2. Record type
      if (typeIdx >= 0 && typeIdx < row.length) {
        final typeRaw = row[typeIdx].toString().trim();
        if (typeRaw.isNotEmpty && _matchRecordType(typeRaw) == null) {
          _recordTypeInvalidQueue.add(RecordTypeInvalidItem(
            rowCsvIndex: i,
            recordName: recordName,
            rawValue: typeRaw,
          ));
        }
      }

      // 3. Artists
      if (artistsIdx >= 0 && artistsIdx < row.length) {
        final artistsRaw = row[artistsIdx].toString().trim();
        if (artistsRaw.isNotEmpty) {
          final artistNames = _splitWithSeparators(artistsRaw);
          for (final aName in artistNames) {
            if (aName.isEmpty) continue;
            final aNorm = ChipTextLogic.normalizeForMatch(aName);
            if (aNorm.isEmpty || !dbArtistNorms.contains(aNorm)) {
              _artistMismatchQueue.add(ArtistMismatchItem(
                rowCsvIndex: i,
                recordName: recordName,
                csvArtistName: aName,
                allCsvArtists: artistNames,
              ));
            }
          }
        }
      }

      // 4. Genres
      final invalidGenres = <String>[];
      if (genresIdx >= 0 && genresIdx < row.length) {
        final genresRaw = row[genresIdx].toString().trim();
        if (genresRaw.isNotEmpty) {
          final genreNames = _splitWithSeparators(genresRaw);
          for (final gName in genreNames) {
            if (gName.isEmpty) continue;
            final gNorm = ChipTextLogic.normalizeForMatch(gName);
            if (gNorm.isEmpty || !dbGenreNorms.contains(gNorm)) {
              invalidGenres.add(gName);
            }
          }
        }
      }
      if (invalidGenres.isNotEmpty) {
        _genreMismatchQueue.add(GenreMismatchItem(
          rowCsvIndex: i,
          recordName: recordName,
          invalidGenres: invalidGenres,
        ));
      }

      // 5. Descriptors
      final invalidDescs = <String>[];
      if (descsIdx >= 0 && descsIdx < row.length) {
        final descsRaw = row[descsIdx].toString().trim();
        if (descsRaw.isNotEmpty) {
          final descNames = _splitWithSeparators(descsRaw);
          for (final dName in descNames) {
            if (dName.isEmpty) continue;
            final dNorm = ChipTextLogic.normalizeForMatch(dName);
            if (dNorm.isEmpty || !dbDescNorms.contains(dNorm)) {
              invalidDescs.add(dName);
            }
          }
        }
      }
      if (invalidDescs.isNotEmpty) {
        _descMismatchQueue.add(DescMismatchItem(
          rowCsvIndex: i,
          recordName: recordName,
          invalidDescriptors: invalidDescs,
        ));
      }

      // 6. Streaming names
      final unrecognizedStreaming = <String>[];
      if (streamingIdx >= 0 && streamingIdx < row.length) {
        final streamRaw = row[streamingIdx].toString().trim();
        if (streamRaw.isNotEmpty) {
          final streamNames = _splitWithSeparators(streamRaw);
          for (final sName in streamNames) {
            if (sName.isEmpty) continue;
            if (_matchStreamingName(sName) == null) {
              unrecognizedStreaming.add(sName);
            }
          }
        }
      }
      if (unrecognizedStreaming.isNotEmpty) {
        _streamingWarningQueue.add(StreamingWarningItem(
          rowCsvIndex: i,
          recordName: recordName,
          unrecognizedNames: unrecognizedStreaming,
        ));
      }

      // 7. Streaming URL count mismatch (silently handled, summarized only)
      if (streamingIdx >= 0 && streamingIdx < row.length &&
          urlIdx >= 0 && urlIdx < row.length) {
        final streamRaw = row[streamingIdx].toString().trim();
        final urlRaw = row[urlIdx].toString().trim();
        final streamCount = streamRaw.isEmpty ? 0 : _splitWithSeparators(streamRaw).length;
        final urlCount = urlRaw.isEmpty ? 0 : _splitWithSeparators(urlRaw).length;
        if (streamCount < urlCount) {
          _extraUrlRows++;
        }
      }

      // 8. Release date
      if (releaseDateIdx >= 0 && releaseDateIdx < row.length) {
        final dateRaw = row[releaseDateIdx].toString().trim();
        if (dateRaw.isNotEmpty && !_isValidDateFormat(dateRaw)) {
          _dateFormatWarningQueue.add(DateFormatWarningItem(
            rowCsvIndex: i,
            recordName: recordName,
            fieldName: 'release_date',
            rawValue: dateRaw,
          ));
        }
      }

      // 9. Status
      if (statusIdx >= 0 && statusIdx < row.length) {
        final statusRaw = row[statusIdx].toString().trim().toLowerCase();
        if (statusRaw.isNotEmpty) {
          final isFinished = statusRaw == 'finished' ||
              statusRaw == 'false' || statusRaw == 'f' || statusRaw == '0';
          final isActive = statusRaw == 'active' ||
              statusRaw == 'true' || statusRaw == 't' || statusRaw == '1';
          if (!isFinished && !isActive) {
            _statusWarningCount++;
          }
        }
      }
    }
  }

  Future<void> startImport() async {
    if (_importing) return;
    _importing = true;
    _importError = null;
    _importSuccess = null;
    _importPhase = ImportPhase.pass1;
    notifyListeners();

    try {
      final type = _importEntityTypeSelection;
      final rows = _importRows;
      if (type == null || rows == null || rows.length <= 1) {
        _importError = 'No data rows found.';
        _importPhase = ImportPhase.idle;
        return;
      }

      _importExistingDbNorms = {
        ..._artists.map(
            (e) => ChipTextLogic.normalizeForMatch(e.entity.artistName)),
        ..._genres
            .map((e) => ChipTextLogic.normalizeForMatch(e.entity.genreName)),
        ..._descriptors.map(
            (e) => ChipTextLogic.normalizeForMatch(e.entity.descriptorName)),
      };

      // date_added gate (full database only)
      if (type == ImportEntityType.fullDatabase &&
          _importHeaders.contains('date_added')) {
        _dateAddedViolation = true;
        _importPhase = ImportPhase.rectification;
        _importing = false;
        notifyListeners();
        return;
      }

      // Pass 1: validation
      if (type == ImportEntityType.fullDatabase) {
        _importPass1Headers = List<String>.from(_importHeaders);
        await _validateFullDatabaseImport();
      } else {
        await _validateStandaloneImport(type, rows);
      }

      _importing = false;
      notifyListeners();

      _decideAfterValidation();
    } catch (e) {
      _importError = 'Import failed: $e';
      _importPhase = ImportPhase.idle;
      _importing = false;
      notifyListeners();
    }
  }

  Future<void> _validateStandaloneImport(
      ImportEntityType type, List<List<dynamic>> rows) async {
    _importPass1Headers = List<String>.from(_importHeaders);
    _importModifiedRows = {};
    _skippedTupleRowIndexes = {};
    _parentNotFoundQueue = [];
    _parentNotFoundIndex = 0;
    _separatorWarningQueue = [];
    _separatorWarningIndex = 0;

    final dataRows = rows.sublist(1);

    final isGenre = type == ImportEntityType.genres;
    final isDesc = type == ImportEntityType.descriptors;

    final nameIdx = _detectColumn(_importPass1Headers, [
      'name',
      if (isGenre) ...['genre', 'genres', 'genre_name', 'genrename', 'genre name'],
      if (isDesc) ...['descriptor', 'descriptors', 'descriptor_name', 'descriptorname', 'descriptor name'],
    ]);
    final parentIdx = _detectColumn(_importPass1Headers, [
      'parent',
      if (isGenre) ...['parent_genre', 'parentgenre', 'parent genre'],
      if (isDesc) ...['parent_descriptor', 'parentdescriptor', 'parent descriptor'],
    ]);
    _parentColumnMissing = (isGenre || isDesc) && parentIdx < 0;
    final typeIdx = _importPass1Headers.indexOf('type');

    final existingNames = <String>{};
    if (isGenre) {
      existingNames.addAll(_genres.map((e) => ChipTextLogic.normalizeForMatch(e.entity.genreName)));
    } else {
      existingNames.addAll(_descriptors.map((e) => ChipTextLogic.normalizeForMatch(e.entity.descriptorName)));
    }

    final seen = <String>{};
    for (var i = 0; i < dataRows.length; i++) {
      if (i % 50 == 0) await Future.delayed(Duration.zero);
      final row = dataRows[i];
      if (typeIdx >= 0 && typeIdx < row.length) {
        final t = row[typeIdx].toString().trim().toLowerCase();
        if (t != (isGenre ? 'genre' : 'descriptor') && t.isNotEmpty) continue;
      }
      final name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (name.isEmpty) continue;
      final norm = ChipTextLogic.normalizeForMatch(name);
      if (seen.contains(norm)) continue;
      seen.add(norm);

      if (existingNames.contains(norm)) continue;

      if (parentIdx >= 0 && parentIdx < row.length) {
        final parsed = parseParentCell(row[parentIdx].toString());
        if (parsed.mixed) {
          _separatorWarningQueue.add(SeparatorWarningItem(
            rowCsvIndex: i,
            recordName: name,
            fieldName: 'parent',
            rawValue: row[parentIdx].toString().trim(),
          ));
        } else {
          for (final token in parsed.tokens) {
            final tokenNorm = ChipTextLogic.normalizeForMatch(token);
            if (!existingNames.contains(tokenNorm)) {
              _parentNotFoundQueue.add(ParentNotFoundItem(
                rowCsvIndex: i,
                childName: name,
                parentName: token,
              ));
            }
          }
        }
      }
    }
  }

  bool get _hasPendingQueues {
    return _recordTypeInvalidQueue.isNotEmpty ||
        _artistMismatchQueue.isNotEmpty ||
        _genreMismatchQueue.isNotEmpty ||
        _descMismatchQueue.isNotEmpty ||
        _streamingWarningQueue.isNotEmpty ||
        _separatorWarningQueue.isNotEmpty ||
        _dateFormatWarningQueue.isNotEmpty ||
        _parentNotFoundQueue.isNotEmpty;
  }

  void _decideAfterValidation() {
    final type = _importEntityTypeSelection;
    if (_parentColumnMissing &&
        (type == ImportEntityType.genres ||
            type == ImportEntityType.descriptors)) {
      _parentColumnGatePending = true;
      _importPhase = ImportPhase.rectification;
      notifyListeners();
      return;
    }
    if (_hasPendingQueues) {
      _importPhase = ImportPhase.rectification;
      notifyListeners();
      return;
    }
    if (_importValid <= 0) {
      _buildImportSummary();
      _importPhase = ImportPhase.summary;
      notifyListeners();
      return;
    }
    _runPass2();
  }

  Future<void> _runPass2() async {
    _importing = true;
    _importPhase = ImportPhase.pass2;
    notifyListeners();
    try {
      await _executePass2();
      await loadAll();
      ToastUtils.showSuccess('Import completed successfully.');
      _buildImportSummary();
      _importPhase = ImportPhase.summary;
    } catch (e) {
      _importError = 'Pass 2 failed: $e';
      _importPhase = ImportPhase.idle;
    } finally {
      _importing = false;
      notifyListeners();
    }
  }

  void _checkAutoAdvance() {
    if (_dateAddedViolation) return;
    if (_parentColumnGatePending) return;
    if (_importPhase != ImportPhase.rectification) return;
    if (!allRectified) return;
    if (_importValid <= 0) {
      _buildImportSummary();
      _importPhase = ImportPhase.summary;
      notifyListeners();
      return;
    }
    _runPass2();
  }

  Future<void> _executePass2() async {
    final type = _importEntityTypeSelection;
    if (type == null) return;

    switch (type) {
      case ImportEntityType.artists:
        await _importArtists();
        break;
      case ImportEntityType.genres:
        await _importGenres();
        break;
      case ImportEntityType.descriptors:
        await _importDescriptors();
        break;
      case ImportEntityType.fullDatabase:
        await _importFullDatabase();
        break;
    }
  }

  @visibleForTesting
  static List<List<dynamic>> overlayRows(
      List<List<dynamic>> base, Map<int, List<dynamic>> modifications) {
    if (modifications.isEmpty) return base;
    return List<List<dynamic>>.generate(
      base.length,
      (i) => modifications[i] ?? base[i],
    );
  }

  List<List<dynamic>> _pass2Rows() {
    final base = _importRows?.sublist(1) ?? <List<dynamic>>[];
    return overlayRows(base, _importModifiedRows);
  }

  void _buildImportSummary() {
    _importedRecords = [];
    _skippedRecords = [];

    final type = _importEntityTypeSelection;
    if (type == null) return;

    final headers =
        _importModifiedRows.isNotEmpty ? _importPass1Headers : _importHeaders;
    final rows = _pass2Rows();

    if (type == ImportEntityType.fullDatabase) {
      final nameIdx = _detectColumn(headers, const [
        'record_name', 'recordname', 'record name', 'name',
      ]);
      final artistsIdx = _detectColumn(headers, const [
        'artists', 'artist', 'artist_name', 'artistname', 'artist name',
      ]);
      final skippedIndices = _validatedSkipRowIndexes.toList()..sort();
      final skipMap = <int, ImportSummarySkipped>{};
      for (var k = 0; k < skippedIndices.length; k++) {
        skipMap[skippedIndices[k]] = _validatedSkippedRecords[k];
      }
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (_skippedTupleRowIndexes.contains(i)) continue;
        final skippedEntry = skipMap[i];
        if (skippedEntry != null) {
          _skippedRecords.add(skippedEntry);
          continue;
        }
        final recordName = nameIdx >= 0 && nameIdx < row.length
            ? row[nameIdx].toString().trim()
            : '';
        if (recordName.isEmpty) {
          _skippedRecords.add(const ImportSummarySkipped(
              recordName: '(empty)', reason: 'Empty name'));
          continue;
        }
        final artists = artistsIdx >= 0 && artistsIdx < row.length
            ? row[artistsIdx].toString().trim()
            : '';
        _importedRecords
            .add(ImportSummaryRecord(recordName: recordName, artists: artists));
      }
    } else {
      final nameIdx = _detectColumn(headers, const [
        'name',
        'artist', 'artists', 'artist_name', 'artistname', 'artist name',
        'genre', 'genres', 'genre_name', 'genrename', 'genre name',
        'descriptor', 'descriptors', 'descriptor_name', 'descriptorname',
        'descriptor name',
      ]);
      final seenNames = <String>{};
      final dbNorms = _importExistingDbNorms;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final name = nameIdx >= 0 && nameIdx < row.length
            ? row[nameIdx].toString().trim()
            : '';
        if (name.isEmpty) {
          if (_skippedTupleRowIndexes.contains(i)) continue;
          _skippedRecords.add(const ImportSummarySkipped(
              recordName: '(empty)', reason: 'Empty name'));
          continue;
        }
        final norm = ChipTextLogic.normalizeForMatch(name);
        if (seenNames.contains(norm)) {
          _skippedRecords.add(ImportSummarySkipped(
              recordName: name, reason: 'Duplicate within the file'));
          continue;
        }
        seenNames.add(norm);
        if (dbNorms.contains(norm)) {
          _skippedRecords.add(ImportSummarySkipped(
              recordName: name, reason: 'Already in the database'));
          continue;
        }
        _importedRecords.add(ImportSummaryRecord(recordName: name, artists: ''));
      }
    }
  }

  void dismissDialog() {
    _clearImportData();
    _importError = null;
    _importSuccess = null;
    notifyListeners();
  }

  @visibleForTesting
  void debugBuildImportSummary() => _buildImportSummary();

  Future<void> _importArtists() async {
    final rows = _pass2Rows();
    if (rows.isEmpty) return;

    final allHeaders = _importModifiedRows.isNotEmpty
        ? _importPass1Headers
        : _importHeaders;

    final nameIdx = _detectColumn(allHeaders, const [
      'name',
      'artist',
      'artists',
      'artist_name',
      'artistname',
      'artist name',
    ]);
    final typeIdx = allHeaders.indexOf('type');

    final dbNames =
        _artists.map((e) => e.entity.artistName.toLowerCase()).toSet();
    final seen = <String>{};
    final toInsert = <String>[];

    for (final row in rows) {
      if (typeIdx >= 0 && typeIdx < row.length) {
        final t = row[typeIdx].toString().trim().toLowerCase();
        if (t != 'artist' && t.isNotEmpty) continue;
      }
      final name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (seen.contains(lower) || dbNames.contains(lower)) continue;
      seen.add(lower);
      toInsert.add(name);
    }
    if (toInsert.isNotEmpty) {
      await _repo.batchInsertArtists(toInsert);
      await _repo.logAction(
        action: 'import_artists',
        tableName: 'artists',
        details: {'count': toInsert.length},
      );
    }
  }

  Future<void> _importGenres() async {
    final rows = _pass2Rows();
    if (rows.isEmpty) return;

    final allHeaders = _importModifiedRows.isNotEmpty
        ? _importPass1Headers
        : _importHeaders;

    final nameIdx = _detectColumn(allHeaders, const [
      'name',
      'genre',
      'genres',
      'genre_name',
      'genrename',
      'genre name',
    ]);
    final parentIdx = _detectColumn(allHeaders, const [
      'parent',
      'parent_genre',
      'parentgenre',
      'parent genre',
    ]);
    final typeIdx = allHeaders.indexOf('type');

    final existingNameToId = <String, int>{};
    for (final e in _genres) {
      existingNameToId[e.entity.genreName.toLowerCase()] = e.entity.genreId!;
    }

    final seen = <String>{};
    final toInsertNames = <String>[];
    final parentRefs = <int, List<String>>{};

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (typeIdx >= 0 && typeIdx < row.length) {
        final t = row[typeIdx].toString().trim().toLowerCase();
        if (t != 'genre' && t.isNotEmpty) continue;
      }
      final name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (seen.contains(lower) || existingNameToId.containsKey(lower)) continue;
      seen.add(lower);

      final idx = toInsertNames.length;
      toInsertNames.add(name);

      if (parentIdx >= 0 && parentIdx < row.length) {
        final parsed = parseParentCell(row[parentIdx].toString());
        if (parsed.tokens.isNotEmpty) {
          parentRefs[idx] = parsed.tokens;
        }
      }
    }

    if (toInsertNames.isEmpty) return;

    final newNameToId = await _repo.batchInsertGenres(toInsertNames);

    final newLowerToId = <String, int>{
      for (final e in newNameToId.entries) e.key.toLowerCase(): e.value,
    };
    final allNameToId = <String, int>{...existingNameToId, ...newLowerToId};
    final edges = resolveHierarchyEdges(
      insertedNames: toInsertNames,
      parentTokens: parentRefs,
      allNameToId: allNameToId,
    );
    await _repo.batchInsertGenreHierarchy(edges);
    await _repo.logAction(
      action: 'import_genres',
      tableName: 'genres',
      details: {
        'count': toInsertNames.length,
        'hierarchy_edges': edges.length,
      },
    );
  }

  Future<void> _importDescriptors() async {
    final rows = _pass2Rows();
    if (rows.isEmpty) return;

    final allHeaders = _importModifiedRows.isNotEmpty
        ? _importPass1Headers
        : _importHeaders;

    final nameIdx = _detectColumn(allHeaders, const [
      'name',
      'descriptor',
      'descriptors',
      'descriptor_name',
      'descriptorname',
      'descriptor name',
    ]);
    final parentIdx = _detectColumn(allHeaders, const [
      'parent',
      'parent_descriptor',
      'parentdescriptor',
      'parent descriptor',
    ]);
    final typeIdx = allHeaders.indexOf('type');

    final existingNameToId = <String, int>{};
    for (final e in _descriptors) {
      existingNameToId[e.entity.descriptorName.toLowerCase()] =
          e.entity.descriptorId!;
    }

    final seen = <String>{};
    final toInsertNames = <String>[];
    final parentRefs = <int, List<String>>{};

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (typeIdx >= 0 && typeIdx < row.length) {
        final t = row[typeIdx].toString().trim().toLowerCase();
        if (t != 'descriptor' && t.isNotEmpty) continue;
      }
      final name = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (seen.contains(lower) || existingNameToId.containsKey(lower)) continue;
      seen.add(lower);

      final idx = toInsertNames.length;
      toInsertNames.add(name);

      if (parentIdx >= 0 && parentIdx < row.length) {
        final parsed = parseParentCell(row[parentIdx].toString());
        if (parsed.tokens.isNotEmpty) {
          parentRefs[idx] = parsed.tokens;
        }
      }
    }

    if (toInsertNames.isEmpty) return;

    final newNameToId = await _repo.batchInsertDescriptors(toInsertNames);

    final newLowerToId = <String, int>{
      for (final e in newNameToId.entries) e.key.toLowerCase(): e.value,
    };
    final allNameToId = <String, int>{...existingNameToId, ...newLowerToId};
    final edges = resolveHierarchyEdges(
      insertedNames: toInsertNames,
      parentTokens: parentRefs,
      allNameToId: allNameToId,
    );
    await _repo.batchInsertDescriptorHierarchy(edges);
    await _repo.logAction(
      action: 'import_descriptors',
      tableName: 'descriptors',
      details: {
        'count': toInsertNames.length,
        'hierarchy_edges': edges.length,
      },
    );
  }

  Future<void> _importFullDatabase() async {
    final rows = _pass2Rows();
    if (rows.isEmpty) return;

    final allHeaders = _importModifiedRows.isNotEmpty
        ? _importPass1Headers
        : _importHeaders;

    // Detect column indices
    final nameIdx = _detectColumn(allHeaders, const [
      'record_name', 'recordname', 'record name', 'name',
    ]);
    final artistsIdx = _detectColumn(allHeaders, const [
      'artists', 'artist', 'artist_name', 'artistname', 'artist name',
    ]);
    final genresIdx = _detectColumn(allHeaders, const [
      'genres', 'genre', 'genre_name', 'genrename', 'genre name',
    ]);
    final descsIdx = _detectColumn(allHeaders, const [
      'descriptors', 'descriptor', 'descriptor_name', 'descriptorname',
      'descriptor name',
    ]);
    final releaseDateIdx = _detectColumn(allHeaders, const [
      'release_date', 'releasedate', 'release date', 'date',
    ]);
    final typeIdx = _detectColumn(allHeaders, const ['type']);
    final streamingIdx = _detectColumn(allHeaders, const [
      'streaming', 'streamings', 'streaming_service', 'streamingservice',
    ]);
    final urlIdx = _detectColumn(allHeaders, const [
      'url', 'urls', 'streaming_url', 'streamingurl', 'streaming url',
    ]);
    final commentsIdx = _detectColumn(allHeaders, const ['comments']);
    final statusIdx = _detectColumn(allHeaders, const ['status']);

    // Build name→ID maps from DB (no new entity creation)
    final artistNameToId = <String, int>{};
    for (final e in _artists) {
      artistNameToId[ChipTextLogic.normalizeForMatch(e.entity.artistName)] =
          e.entity.artistId!;
    }
    final genreNameToId = <String, int>{};
    for (final e in _genres) {
      genreNameToId[ChipTextLogic.normalizeForMatch(e.entity.genreName)] =
          e.entity.genreId!;
    }
    final descNameToId = <String, int>{};
    for (final e in _descriptors) {
      descNameToId[ChipTextLogic.normalizeForMatch(e.entity.descriptorName)] =
          e.entity.descriptorId!;
    }

    // Parse each valid row
    final recordsToInsert = <Record>[];
    final recordRowIndices = <int>[]; // parallel to recordsToInsert
    final artistEdges = <(int, int, int)>[]; // (recordIndex, artistId, order)
    final genreEdges = <(int, int, int)>[];
    final descEdges = <(int, int, int)>[];
    final streamingRows = <(int, String, String)>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final recordName = nameIdx >= 0 && nameIdx < row.length
          ? row[nameIdx].toString().trim()
          : '';
      if (recordName.isEmpty) continue;

      // Record type
      final recordType = typeIdx >= 0 && typeIdx < row.length
          ? row[typeIdx].toString().trim()
          : null;

      // Release date
      final releaseDate = releaseDateIdx >= 0 && releaseDateIdx < row.length
          ? row[releaseDateIdx].toString().trim()
          : null;

      // Comments
      final comments = commentsIdx >= 0 && commentsIdx < row.length
          ? row[commentsIdx].toString().trim()
          : null;

      // Status
      var status = false; // default = Active
      if (statusIdx >= 0 && statusIdx < row.length) {
        final s = row[statusIdx].toString().trim().toLowerCase();
        if (s == 'finished' || s == 'false' || s == 'f' || s == '0') {
          status = true;
        } else if (s == 'active' || s == 'true' || s == 't' || s == '1') {
          status = false;
        }
      }

      final recIdx = recordsToInsert.length;
      recordsToInsert.add(Record(
        recordName: recordName,
        recordType: recordType?.isNotEmpty == true ? recordType : null,
        releaseDate: releaseDate?.isNotEmpty == true ? releaseDate : null,
        dateAdded: null,
        comments: comments?.isNotEmpty == true ? comments : null,
        status: status,
      ));
      recordRowIndices.add(i);

      // Artists
      if (artistsIdx >= 0 && artistsIdx < row.length) {
        final artistsRaw = row[artistsIdx].toString().trim();
        if (artistsRaw.isNotEmpty) {
          final artistNames = _splitWithSeparators(artistsRaw);
          for (var a = 0; a < artistNames.length; a++) {
            final aNorm = ChipTextLogic.normalizeForMatch(artistNames[a]);
            final aId = artistNameToId[aNorm];
            if (aId != null) {
              artistEdges.add((recIdx, aId, a + 1));
            }
          }
        }
      }

      // Genres
      if (genresIdx >= 0 && genresIdx < row.length) {
        final genresRaw = row[genresIdx].toString().trim();
        if (genresRaw.isNotEmpty) {
          final genreNames = _splitWithSeparators(genresRaw);
          for (var g = 0; g < genreNames.length; g++) {
            final gNorm = ChipTextLogic.normalizeForMatch(genreNames[g]);
            final gId = genreNameToId[gNorm];
            if (gId != null) {
              genreEdges.add((recIdx, gId, g + 1));
            }
          }
        }
      }

      // Descriptors
      if (descsIdx >= 0 && descsIdx < row.length) {
        final descsRaw = row[descsIdx].toString().trim();
        if (descsRaw.isNotEmpty) {
          final descNames = _splitWithSeparators(descsRaw);
          for (var d = 0; d < descNames.length; d++) {
            final dNorm = ChipTextLogic.normalizeForMatch(descNames[d]);
            final dId = descNameToId[dNorm];
            if (dId != null) {
              descEdges.add((recIdx, dId, d + 1));
            }
          }
        }
      }

      // Streaming
      if (streamingIdx >= 0 && streamingIdx < row.length) {
        final streamRaw = row[streamingIdx].toString().trim();
        final urlRaw = urlIdx >= 0 && urlIdx < row.length
            ? row[urlIdx].toString().trim()
            : '';
        if (streamRaw.isNotEmpty) {
          final streamNames = _splitWithSeparators(streamRaw);
          final urls = urlRaw.isNotEmpty ? _splitWithSeparators(urlRaw) : [];
          for (var s = 0; s < streamNames.length; s++) {
            final dbVal = _matchStreamingName(streamNames[s]);
            final url = s < urls.length ? urls[s] : '';
            streamingRows.add((recIdx, dbVal ?? streamNames[s], url));
          }
        }
      }
    }

    if (recordsToInsert.isEmpty) return;

    // Batch insert records
    final nameToRecordId = await _repo.batchInsertRecords(recordsToInsert);

    // Resolve record IDs and batch insert junction rows
    final resolvedArtistEdges = <(int, int, int)>[];
    final resolvedGenreEdges = <(int, int, int)>[];
    final resolvedDescEdges = <(int, int, int)>[];
    final resolvedStreaming = <(int, String, String)>[];

    for (var r = 0; r < recordsToInsert.length; r++) {
      final rId = nameToRecordId[recordsToInsert[r].recordName];
      if (rId == null) continue;
      for (final e in artistEdges.where((e) => e.$1 == r)) {
        resolvedArtistEdges.add((rId, e.$2, e.$3));
      }
      for (final e in genreEdges.where((e) => e.$1 == r)) {
        resolvedGenreEdges.add((rId, e.$2, e.$3));
      }
      for (final e in descEdges.where((e) => e.$1 == r)) {
        resolvedDescEdges.add((rId, e.$2, e.$3));
      }
      for (final e in streamingRows.where((e) => e.$1 == r)) {
        resolvedStreaming.add((rId, e.$2, e.$3));
      }
    }

    await _repo.batchInsertRecordArtists(resolvedArtistEdges);
    await _repo.batchInsertRecordGenres(resolvedGenreEdges);
    await _repo.batchInsertRecordDescriptors(resolvedDescEdges);
    await _repo.batchInsertRecordStreaming(resolvedStreaming);

    await _repo.logAction(
      action: 'import_records',
      tableName: 'records',
      details: {
        'records': recordsToInsert.length,
        'artist_links': resolvedArtistEdges.length,
        'genre_links': resolvedGenreEdges.length,
        'descriptor_links': resolvedDescEdges.length,
        'streaming_links': resolvedStreaming.length,
      },
    );
  }

  // --- Two-pass: Parent rectification ---

  void rectifyParentNotFound(int? selectedParentId) {
    if (_parentNotFoundIndex >= _parentNotFoundQueue.length) return;
    final item = _parentNotFoundQueue[_parentNotFoundIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;
    final rowIdx = item.rowCsvIndex;
    if (rowIdx < 0 || rowIdx >= rows.length - 1) return;

    final parentIdx = _detectColumn(_importPass1Headers, const [
      'parent', 'parent_genre', 'parentgenre', 'parent genre',
      'parent_descriptor', 'parentdescriptor', 'parent descriptor',
    ]);

    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);

    if (parentIdx >= 0 && selectedParentId != null) {
      final allEntities = [
        ..._genres.map((e) => (e.entity.genreId, e.entity.genreName)),
        ..._descriptors
            .map((e) => (e.entity.descriptorId, e.entity.descriptorName)),
      ];
      final match = allEntities.where((e) => e.$1 == selectedParentId);
      if (match.isNotEmpty) {
        row[parentIdx] = replaceParentToken(
          row[parentIdx].toString(),
          ChipTextLogic.normalizeForMatch(item.parentName),
          match.first.$2,
        );
      }
    } else if (parentIdx >= 0) {
      row[parentIdx] = '';
    }

    _importModifiedRows[rowIdx] = row;

    _parentNotFoundIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void skipParentNotFoundTuple() {
    if (_parentNotFoundIndex >= _parentNotFoundQueue.length) return;
    final item = _parentNotFoundQueue[_parentNotFoundIndex];
    item.skipped = true;
    _skippedTupleRowIndexes.add(item.rowCsvIndex);
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) {
      row[nameIdx] = '';
    }
    _importModifiedRows[rowIdx] = row;

    _parentNotFoundIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  // --- Full DB: Record Type Invalid Rectification ---

  void proceedRecordTypeInvalid() {
    if (_recordTypeInvalidIndex >= _recordTypeInvalidQueue.length) return;
    final item = _recordTypeInvalidQueue[_recordTypeInvalidIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final typeIdx = _detectColumn(_importPass1Headers, const ['type']);
    if (typeIdx >= 0 && typeIdx < row.length) row[typeIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _recordTypeInvalidIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void rectifyRecordTypeInvalid(String chosen) {
    if (_recordTypeInvalidIndex >= _recordTypeInvalidQueue.length) return;
    final item = _recordTypeInvalidQueue[_recordTypeInvalidIndex];
    if (_matchRecordType(chosen) == null) return;
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final typeIdx = _detectColumn(_importPass1Headers, const ['type']);
    if (typeIdx >= 0 && typeIdx < row.length) row[typeIdx] = chosen;

    _importModifiedRows[rowIdx] = row;
    _recordTypeInvalidIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  // --- Full DB: Artist Mismatch Rectification ---

  void rectifyArtistMismatch(int? selectedArtistId) {
    if (_artistMismatchIndex >= _artistMismatchQueue.length) return;
    final item = _artistMismatchQueue[_artistMismatchIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final artistsIdx = _detectColumn(_importPass1Headers, const [
      'artists', 'artist', 'artist_name', 'artistname', 'artist name',
    ]);

    if (artistsIdx >= 0 && artistsIdx < row.length && selectedArtistId != null) {
      final match = _artists.where((e) => e.entity.artistId == selectedArtistId);
      if (match.isNotEmpty) {
        final oldVal = row[artistsIdx].toString();
        final replacement = match.first.entity.artistName;
        final newParts = <String>[];
        for (final part in _splitWithSeparators(oldVal)) {
          if (ChipTextLogic.normalizeForMatch(part) ==
              ChipTextLogic.normalizeForMatch(item.csvArtistName)) {
            newParts.add(replacement);
          } else {
            newParts.add(part);
          }
        }
        row[artistsIdx] = newParts.join(', ');
      }
    }

    _importModifiedRows[rowIdx] = row;
    _artistMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void skipArtistMismatchTuple() {
    if (_artistMismatchIndex >= _artistMismatchQueue.length) return;
    final item = _artistMismatchQueue[_artistMismatchIndex];
    item.skipped = true;
    _skippedTupleRowIndexes.add(item.rowCsvIndex);
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) {
      row[nameIdx] = '';
    }
    _importModifiedRows[rowIdx] = row;
    _artistMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void proceedArtistMismatch() {
    if (_artistMismatchIndex >= _artistMismatchQueue.length) return;
    _removeArtistEntry(_artistMismatchQueue[_artistMismatchIndex]);
    _artistMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void autoFixArtistMismatch() => proceedArtistMismatch();

  void _removeArtistEntry(ArtistMismatchItem item) {
    final rows = _importPass1Rows;
    if (rows == null) return;
    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final artistsIdx = _detectColumn(_importPass1Headers, const [
      'artists', 'artist', 'artist_name', 'artistname', 'artist name',
    ]);
    if (artistsIdx >= 0 && artistsIdx < row.length) {
      final parts = _splitWithSeparators(row[artistsIdx].toString());
      final kept = parts
          .where((part) => ChipTextLogic.normalizeForMatch(part) !=
              ChipTextLogic.normalizeForMatch(item.csvArtistName))
          .toList();
      row[artistsIdx] = kept.join(', ');
    }
    _importModifiedRows[rowIdx] = row;
  }

  // --- Full DB: Streaming Warning Rectification ---

  void proceedStreamingWarning() {
    if (_streamingWarningIndex >= _streamingWarningQueue.length) return;
    final item = _streamingWarningQueue[_streamingWarningIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final streamingIdx = _detectColumn(_importPass1Headers, const [
      'streaming', 'streamings', 'streaming_service', 'streamingservice',
    ]);
    final urlIdx = _detectColumn(_importPass1Headers, const [
      'url', 'urls', 'streaming_url', 'streamingurl', 'streaming url',
    ]);
    if (streamingIdx >= 0 && streamingIdx < row.length) row[streamingIdx] = '';
    if (urlIdx >= 0 && urlIdx < row.length) row[urlIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _streamingWarningIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void autoFixStreamingWarning() {
    if (_streamingWarningIndex >= _streamingWarningQueue.length) return;
    final item = _streamingWarningQueue[_streamingWarningIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final streamingIdx = _detectColumn(_importPass1Headers, const [
      'streaming', 'streamings', 'streaming_service', 'streamingservice',
    ]);
    if (streamingIdx >= 0 && streamingIdx < row.length) {
      final raw = row[streamingIdx].toString();
      final parts = _splitWithSeparators(raw);
      final fixed = <String>[];
      for (final part in parts) {
        final matched = _matchStreamingName(part);
        fixed.add(matched ?? part);
      }
      row[streamingIdx] = fixed.join(', ');
    }

    _importModifiedRows[rowIdx] = row;
    _streamingWarningIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void skipStreamingWarningTuple() {
    if (_streamingWarningIndex >= _streamingWarningQueue.length) return;
    final item = _streamingWarningQueue[_streamingWarningIndex];
    item.skipped = true;
    _skippedTupleRowIndexes.add(item.rowCsvIndex);
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) row[nameIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _streamingWarningIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  // --- Full DB: Separator Warning Rectification ---

  void proceedSeparatorWarning() {
    if (_separatorWarningIndex >= _separatorWarningQueue.length) return;
    final item = _separatorWarningQueue[_separatorWarningIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    if (item.fieldName == 'parent') {
      final parentIdx = _detectColumn(_importPass1Headers, const [
        'parent', 'parent_genre', 'parentgenre', 'parent genre',
        'parent_descriptor', 'parentdescriptor', 'parent descriptor',
      ]);
      if (parentIdx >= 0 && parentIdx < row.length) row[parentIdx] = '';
    } else {
      final streamingIdx = _detectColumn(_importPass1Headers, const [
        'streaming', 'streamings', 'streaming_service', 'streamingservice',
      ]);
      final urlIdx = _detectColumn(_importPass1Headers, const [
        'url', 'urls', 'streaming_url', 'streamingurl', 'streaming url',
      ]);
      if (streamingIdx >= 0 && streamingIdx < row.length) {
        row[streamingIdx] = '';
      }
      if (urlIdx >= 0 && urlIdx < row.length) row[urlIdx] = '';
    }

    _importModifiedRows[rowIdx] = row;
    _separatorWarningIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void skipSeparatorWarningTuple() {
    if (_separatorWarningIndex >= _separatorWarningQueue.length) return;
    final item = _separatorWarningQueue[_separatorWarningIndex];
    item.skipped = true;
    _skippedTupleRowIndexes.add(item.rowCsvIndex);
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) row[nameIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _separatorWarningIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  // --- Full DB: Date Format Warning Rectification ---

  void proceedDateFormatWarning() {
    if (_dateFormatWarningIndex >= _dateFormatWarningQueue.length) return;
    final item = _dateFormatWarningQueue[_dateFormatWarningIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final dateIdx = _detectColumn(_importPass1Headers, const [
      'release_date', 'releasedate', 'release date', 'date',
    ]);
    if (dateIdx >= 0 && dateIdx < row.length) row[dateIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _dateFormatWarningIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void skipDateFormatWarningTuple() {
    if (_dateFormatWarningIndex >= _dateFormatWarningQueue.length) return;
    final item = _dateFormatWarningQueue[_dateFormatWarningIndex];
    item.skipped = true;
    _skippedTupleRowIndexes.add(item.rowCsvIndex);
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) row[nameIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _dateFormatWarningIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  // --- Full DB: Genre Mismatch ---

  void proceedGenreMismatch() {
    if (_genreMismatchIndex >= _genreMismatchQueue.length) return;
    final item = _genreMismatchQueue[_genreMismatchIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final genresIdx = _detectColumn(_importPass1Headers, const [
      'genres', 'genre', 'genre_name', 'genrename', 'genre name',
    ]);
    if (genresIdx >= 0 && genresIdx < row.length) {
      row[genresIdx] = '';
    }
    _importModifiedRows[rowIdx] = row;
    _genreMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void autoFixGenreMismatch() {
    if (_genreMismatchIndex >= _genreMismatchQueue.length) return;
    final item = _genreMismatchQueue[_genreMismatchIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final genresIdx = _detectColumn(_importPass1Headers, const [
      'genres', 'genre', 'genre_name', 'genrename', 'genre name',
    ]);
    if (genresIdx >= 0 && genresIdx < row.length) {
      final genreNames = _splitWithSeparators(row[genresIdx].toString());
      final valid = genreNames
          .where((n) => !item.invalidGenres.contains(n))
          .toList();
      row[genresIdx] = valid.join(', ');
    }
    _importModifiedRows[rowIdx] = row;
    _genreMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void skipGenreMismatchTuple() {
    if (_genreMismatchIndex >= _genreMismatchQueue.length) return;
    final item = _genreMismatchQueue[_genreMismatchIndex];
    item.skipped = true;
    _skippedTupleRowIndexes.add(item.rowCsvIndex);
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) row[nameIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _genreMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void skipDescMismatchTuple() {
    if (_descMismatchIndex >= _descMismatchQueue.length) return;
    final item = _descMismatchQueue[_descMismatchIndex];
    item.skipped = true;
    _skippedTupleRowIndexes.add(item.rowCsvIndex);
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final nameIdx = _importNameColumnIndex();
    if (nameIdx >= 0 && nameIdx < row.length) row[nameIdx] = '';

    _importModifiedRows[rowIdx] = row;
    _descMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void proceedDescMismatch() {
    if (_descMismatchIndex >= _descMismatchQueue.length) return;
    final item = _descMismatchQueue[_descMismatchIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final descsIdx = _detectColumn(_importPass1Headers, const [
      'descriptors', 'descriptor', 'descriptor_name', 'descriptorname',
      'descriptor name',
    ]);
    if (descsIdx >= 0 && descsIdx < row.length) {
      row[descsIdx] = '';
    }
    _importModifiedRows[rowIdx] = row;
    _descMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  void autoFixDescMismatch() {
    if (_descMismatchIndex >= _descMismatchQueue.length) return;
    final item = _descMismatchQueue[_descMismatchIndex];
    final rows = _importPass1Rows;
    if (rows == null) return;

    final rowIdx = item.rowCsvIndex;
    final row = List<dynamic>.from(
        _importModifiedRows[rowIdx] ?? rows[rowIdx + 1]);
    final descsIdx = _detectColumn(_importPass1Headers, const [
      'descriptors', 'descriptor', 'descriptor_name', 'descriptorname',
      'descriptor name',
    ]);
    if (descsIdx >= 0 && descsIdx < row.length) {
      final descNames = _splitWithSeparators(row[descsIdx].toString());
      final valid = descNames
          .where((n) => !item.invalidDescriptors.contains(n))
          .toList();
      row[descsIdx] = valid.join(', ');
    }
    _importModifiedRows[rowIdx] = row;
    _descMismatchIndex++;
    notifyListeners();
    _checkAutoAdvance();
  }

  // --- Full DB: Date Added Violation ---

  void proceedDateAddedViolation() {
    final rows = _importRows;
    if (rows == null) return;
    final dateAddedIdx = _importHeaders.indexOf('date_added');
    if (dateAddedIdx < 0) return;

    final now = DateTime.now();
    final today =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    for (var i = 0; i < rows.length - 1; i++) {
      final row = List<dynamic>.from(
          _importModifiedRows[i] ?? rows[i + 1]);
      if (dateAddedIdx < row.length) {
        row[dateAddedIdx] = today;
      }
      _importModifiedRows[i] = row;
    }

    // Remove date_added from headers so it doesn't cause issues in import
    _importPass1Headers.remove('date_added');
    _importHeaders.remove('date_added');
    _dateAddedViolation = false;
    _dateAddedResolved = true;
    notifyListeners();
  }

  bool get allParentWarningsHandled =>
      _parentNotFoundIndex >= _parentNotFoundQueue.length;

  void proceedParentColumnGate() {
    _parentColumnGatePending = false;
    notifyListeners();
    if (_hasPendingQueues) {
      _importPhase = ImportPhase.rectification;
      notifyListeners();
      return;
    }
    if (_importValid <= 0) {
      _buildImportSummary();
      _importPhase = ImportPhase.summary;
      notifyListeners();
      return;
    }
    _runPass2();
  }

  void cancelImport() {
    _clearImportData();
    _importError = null;
    _importSuccess = null;
    notifyListeners();
  }

  void clearImport() {
    _clearImportData();
    _importError = null;
    _importSuccess = null;
    notifyListeners();
  }

  void _clearImportData() {
    _importRows = null;
    _importHeaders = [];
    _importFileName = null;
    _importTotal = 0;
    _importValid = 0;
    _importEmptyNames = 0;
    _importDuplicatesInFile = 0;
    _importDuplicatesVsDb = 0;
    _importBrokenParents = 0;
    _importPass1Rows = null;
    _importPass1Headers = [];
    _importModifiedRows = {};
    _skippedTupleRowIndexes = {};
    _parentNotFoundQueue = [];
    _parentNotFoundIndex = 0;
    _artistMismatchQueue = [];
    _artistMismatchIndex = 0;
    _genreMismatchQueue = [];
    _genreMismatchIndex = 0;
    _descMismatchQueue = [];
    _descMismatchIndex = 0;
    _streamingWarningQueue = [];
    _streamingWarningIndex = 0;
    _separatorWarningQueue = [];
    _separatorWarningIndex = 0;
    _dateFormatWarningQueue = [];
    _dateFormatWarningIndex = 0;
    _recordTypeInvalidQueue = [];
    _recordTypeInvalidIndex = 0;
    _statusWarningCount = 0;
    _recordSkipCount = 0;
    _extraUrlRows = 0;
    _validatedSkipRowIndexes = {};
    _validatedSkippedRecords = [];
    if (_existingRecordNormsOverride) {
      _existingRecordNormsLoaded = true;
    } else {
      _existingRecordNorms = {};
      _existingRecordNormsLoaded = false;
    }
    _dateAddedViolation = false;
    _dateAddedResolved = false;
    _parentColumnMissing = false;
    _parentColumnGatePending = false;
    _importExistingDbNorms = {};
    _importedRecords = [];
    _skippedRecords = [];
    _importPhase = ImportPhase.idle;
  }

  // --- Load ---

  Future<void> loadAll() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchArtistsWithRefCount(),
        _repo.fetchGenresWithRefCount(),
        _repo.fetchDescriptorsWithRefCount(),
      ]);
      _artists = results[0] as List<EntityWithRefCount<Artist>>;
      _genres = results[1] as List<EntityWithRefCount<Genre>>;
      _descriptors = results[2] as List<EntityWithRefCount<Descriptor>>;
    } catch (e) {
      _loadError = 'Failed to load: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CRUD: Artists ---

  Future<String?> createArtist(String name) async {
    try {
      await _repo.createArtist(name, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess('Artist "$name" created.');
      return null;
    } catch (e) {
      return 'Failed to create artist: $e';
    }
  }

  Future<String?> renameArtist(int id, String newName) async {
    try {
      await _repo.renameArtist(id, newName, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess('Renamed artist to "$newName".');
      return null;
    } catch (e) {
      return 'Failed to rename artist: $e';
    }
  }

  Future<String?> deleteArtist(int id) async {
    try {
      final entry = _artists.firstWhere((e) => e.entity.artistId == id);
      if (entry.refCount > 0) {
        return 'Cannot delete — referenced by ${entry.refCount} record(s).';
      }
      await _repo.deleteArtist(id, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess('Deleted artist "${entry.entity.artistName}".');
      return null;
    } catch (e) {
      return 'Failed to delete artist: $e';
    }
  }

  // --- Genre/Descriptor Parents ---

  Future<Set<int>> fetchGenreParentIds(int childId) async {
    return _repo.fetchGenreParentIds(childId);
  }

  Future<Set<int>> fetchDescriptorParentIds(int childId) async {
    return _repo.fetchDescriptorParentIds(childId);
  }

  Future<String?> setGenreParents(int childId, Set<int> parentIds) async {
    try {
      await _repo.setGenreParents(childId, parentIds, originTab: 'manage');
      ToastUtils.showSuccess('Genre parents updated.');
      return null;
    } catch (e) {
      return 'Failed to set parents: $e';
    }
  }

  Future<String?> setDescriptorParents(int childId, Set<int> parentIds) async {
    try {
      await _repo.setDescriptorParents(childId, parentIds,
          originTab: 'manage');
      ToastUtils.showSuccess('Descriptor parents updated.');
      return null;
    } catch (e) {
      return 'Failed to set parents: $e';
    }
  }

  // --- CRUD: Genres ---

  Future<String?> createGenre(String name, {Set<int>? parentIds}) async {
    try {
      final genre = await _repo.createGenre(name, originTab: 'manage');
      if (parentIds != null && parentIds.isNotEmpty && genre.genreId != null) {
        await _repo.setGenreParents(genre.genreId!, parentIds,
            originTab: 'manage');
      }
      await loadAll();
      ToastUtils.showSuccess('Genre "$name" created.');
      return null;
    } catch (e) {
      return 'Failed to create genre: $e';
    }
  }

  Future<String?> renameGenre(int id, String newName) async {
    try {
      await _repo.renameGenre(id, newName, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess('Renamed genre to "$newName".');
      return null;
    } catch (e) {
      return 'Failed to rename genre: $e';
    }
  }

  Future<String?> deleteGenre(int id) async {
    try {
      final entry = _genres.firstWhere((e) => e.entity.genreId == id);
      await _repo.deleteGenre(id, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess('Deleted genre "${entry.entity.genreName}".');
      return null;
    } catch (e) {
      return 'Failed to delete genre: $e';
    }
  }

  // --- CRUD: Descriptors ---

  Future<String?> createDescriptor(String name, {Set<int>? parentIds}) async {
    try {
      final descriptor = await _repo.createDescriptor(name,
          originTab: 'manage');
      if (parentIds != null &&
          parentIds.isNotEmpty &&
          descriptor.descriptorId != null) {
        await _repo.setDescriptorParents(descriptor.descriptorId!, parentIds,
            originTab: 'manage');
      }
      await loadAll();
      ToastUtils.showSuccess('Descriptor "$name" created.');
      return null;
    } catch (e) {
      return 'Failed to create descriptor: $e';
    }
  }

  Future<String?> renameDescriptor(int id, String newName) async {
    try {
      await _repo.renameDescriptor(id, newName, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess('Renamed descriptor to "$newName".');
      return null;
    } catch (e) {
      return 'Failed to rename descriptor: $e';
    }
  }

  Future<String?> deleteDescriptor(int id) async {
    try {
      final entry =
          _descriptors.firstWhere((e) => e.entity.descriptorId == id);
      await _repo.deleteDescriptor(id, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess(
          'Deleted descriptor "${entry.entity.descriptorName}".');
      return null;
    } catch (e) {
      return 'Failed to delete descriptor: $e';
    }
  }

  /// Adopt then delete: A's children gain all of A's parents (additively),
  /// then A is deleted normally.
  Future<String?> adoptThenDeleteGenre(int id) async {
    try {
      final entry = _genres.firstWhere((e) => e.entity.genreId == id);
      await _repo.adoptGenreChildren(id, originTab: 'manage');
      await _repo.deleteGenre(id, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess(
          'Deleted genre "${entry.entity.genreName}" (children adopted by '
          'its parents).');
      return null;
    } catch (e) {
      return 'Failed to delete genre: $e';
    }
  }

  Future<String?> adoptThenDeleteDescriptor(int id) async {
    try {
      final entry = _descriptors.firstWhere((e) => e.entity.descriptorId == id);
      await _repo.adoptDescriptorChildren(id, originTab: 'manage');
      await _repo.deleteDescriptor(id, originTab: 'manage');
      await loadAll();
      ToastUtils.showSuccess(
          'Deleted descriptor "${entry.entity.descriptorName}" (children '
          'adopted by its parents).');
      return null;
    } catch (e) {
      return 'Failed to delete descriptor: $e';
    }
  }

  // --- Filtering + Sorting ---

  List<EntityWithRefCount<T>> _filtered<T>(List<EntityWithRefCount<T>> list) {
    var result = List<EntityWithRefCount<T>>.from(list);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      final scored = <(EntityWithRefCount<T>, double)>[];
      for (final e in result) {
        final name = _entityName(e.entity).toLowerCase();
        if (name.isEmpty) continue;
        final contains = name.contains(q);
        final score =
            contains ? 1.0 : CsvUtils.calculateSimilarity(q, name);
        if (contains || score > 0.3) {
          scored.add((e, score));
        }
      }
      scored.sort((a, b) {
        final cmp = b.$2.compareTo(a.$2);
        if (cmp != 0) return cmp;
        return _entityName(a.$1.entity)
            .toLowerCase()
            .compareTo(_entityName(b.$1.entity).toLowerCase());
      });
      return scored.map((s) => s.$1).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case EntitySortField.name:
          cmp = _entityName(a.entity)
              .toLowerCase()
              .compareTo(_entityName(b.entity).toLowerCase());
        case EntitySortField.refCount:
          cmp = a.refCount.compareTo(b.refCount);
        case EntitySortField.childrenCount:
          cmp = a.childrenCount.compareTo(b.childrenCount);
        case EntitySortField.totalRefCount:
          cmp = (a.totalRefCount > 0 ? a.totalRefCount : a.refCount)
              .compareTo(b.totalRefCount > 0 ? b.totalRefCount : b.refCount);
      }
      return _sortAsc ? cmp : -cmp;
    });

    return result;
  }

  String _entityName(dynamic entity) {
    if (entity is Artist) return entity.artistName;
    if (entity is Genre) return entity.genreName;
    if (entity is Descriptor) return entity.descriptorName;
    return '';
  }
}
