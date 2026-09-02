import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/features/database/presentation/providers/database_provider.dart';
import 'package:music_collection/features/database/presentation/screens/database_screen.dart';
import 'package:music_collection/features/insert/presentation/providers/insert_provider.dart';
import 'package:music_collection/features/search/presentation/providers/search_provider.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';
import 'package:provider/provider.dart';

RecordDetails _row({
  required int id,
  required String name,
  bool finished = false,
  String type = 'Album',
  String releaseDate = '1965-04-21',
  String? comments,
}) {
  return RecordDetails(
    record: Record(
      recordId: id,
      recordName: name,
      recordType: type,
      releaseDate: releaseDate,
      dateAdded: '05/07/2026',
      comments: comments,
      status: finished,
    ),
    artists: [
      Artist(artistId: id, artistName: 'Artist $id'),
    ],
    genres: [
      Genre(genreId: id, genreName: 'Genre $id'),
    ],
    descriptors: [
      Descriptor(descriptorId: id, descriptorName: 'Desc $id'),
    ],
    streaming: [
      StreamingService(serviceName: 'Spotify', serviceUrl: ''),
    ],
  );
}

List<RecordDetails> _sampleRows() {
  return [
    _row(id: 1, name: 'Kind of Blue', type: 'Album'),
    _row(id: 2, name: 'A Love Supreme', type: 'Album', comments: 'spiritual jazz'),
    _row(id: 3, name: 'Blue Train', type: 'Album'),
    _row(id: 4, name: 'Moanin', type: 'Album', finished: true),
    _row(id: 5, name: 'Somethin Else', type: 'Album'),
  ];
}

Widget _dbHost(DatabaseProvider db) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<InsertProvider>.value(value: InsertProvider()),
      ChangeNotifierProvider<SearchProvider>.value(value: SearchProvider()),
      ChangeNotifierProvider<SearchResultsProvider>.value(value: db),
      ChangeNotifierProvider<DatabaseProvider>.value(value: db),
    ],
    child: const MaterialApp(
      home: Scaffold(body: DatabaseScreen()),
    ),
  );
}

Future<void> _useSurface(WidgetTester tester, Size logical) async {
  tester.view.physicalSize = Size(
      logical.width * tester.view.devicePixelRatio,
      logical.height * tester.view.devicePixelRatio);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('DatabaseProvider – core logic', () {
    test('presentRows splits active/finished buckets', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.activeResults.length, 4);
      expect(db.finishedResults.length, 1);
      expect(db.totalRows, 5);
    });

    test('default sort is by record name', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      final names = db.sortedRows.map((r) => r.record.recordName).toList();
      expect(names.first, 'A Love Supreme');
      expect(names.last, 'Somethin Else');
    });

    test('setSearchQuery filters by name substring', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchQuery('Blue');
      expect(db.totalRows, 2);
      final names = db.sortedRows.map((r) => r.record.recordName).toList();
      expect(names, containsAll(['Kind of Blue', 'Blue Train']));
    });

    test('setSearchQuery filters by comments', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchQuery('spiritual');
      expect(db.totalRows, 1);
      expect(db.sortedRows.first.record.recordName, 'A Love Supreme');
    });

    test('setSearchQuery with empty string shows all active records', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchQuery('Blue');
      expect(db.totalRows, 2);
      db.setSearchQuery('');
      expect(db.totalRows, 4); // only active bucket (1 is finished)
    });

    test('clearSearch resets to active bucket', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchQuery('Blue');
      expect(db.totalRows, 2);
      db.clearSearch();
      expect(db.totalRows, 4); // active bucket only
      expect(db.searchQuery, '');
    });

    test('cycleSort toggles sort order', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.cycleSort('name');
      final names =
          db.sortedRows.map((r) => r.record.recordName).toList();
      expect(names.first, 'Somethin Else');
    });

    test('clearSorts removes all sorting', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.cycleSort('name');
      db.clearSorts();
      expect(db.sortColumns, isEmpty);
      expect(db.sortPriority('name'), 0);
    });

    test('sortPriority returns correct index', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.sortPriority('name'), 1);
      expect(db.sortPriority('artists'), 0);
      db.cycleSort('artists');
      expect(db.sortPriority('artists'), 2);
    });

    test('setGroupBy and groupedRows works', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setGroupBy('type');
      final grouped = db.groupedRows;
      expect(grouped.length, 1);
      expect(grouped.first.key, 'Album');
      expect(grouped.first.value.length, 5);
    });

    test('setGroupBy(null) removes grouping', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setGroupBy('type');
      expect(db.groupedRows.length, 1);
      db.setGroupBy(null);
      expect(db.groupedRows.length, 1);
      expect(db.groupedRows.first.key, '');
    });

    test('setBucket switches between active and finished', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.currentBucket, ResultBucket.active);
      db.setBucket(ResultBucket.finished);
      expect(db.currentBucket, ResultBucket.finished);
      expect(db.totalRows, 1);
    });

    test('column visibility: frozen columns always shown', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.isColumnShown('name'), true);
      expect(db.isColumnShown('artists'), true);
      expect(db.isColumnShown('genres'), true);
    });

    test('column visibility: all columns always shown (hideShowColumns)', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.hideShowColumns, true);
      expect(db.isColumnShown('streaming'), true);
      expect(db.isColumnShown('comments'), true);
      expect(db.isColumnShown('name'), true);
      db.setColumnVisible('streaming', false);
      expect(db.isColumnShown('streaming'), true);
    });

    test('fuzzy match returns score', () {
      final db = DatabaseProvider();
      final score = db.fuzzyMatch('blu', 'blue');
      expect(score, greaterThan(0.3));
    });

    test('search query matches across all fields', () {
      final rows = [
        _row(id: 1, name: 'Test Record'),
        _row(id: 2, name: 'Another', comments: 'gatefold sleeve'),
      ];
      final db = DatabaseProvider()..presentRows(rows: rows);
      db.setSearchQuery('gatefold');
      expect(db.totalRows, 1);
      expect(db.sortedRows.first.record.recordName, 'Another');
    });

    test('search query matches artist names', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchQuery('Artist 3');
      expect(db.totalRows, 1);
      expect(db.sortedRows.first.record.recordName, 'Blue Train');
    });

    test('memoization: repeated sortedRows call returns same list', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      final first = db.sortedRows;
      final second = db.sortedRows;
      expect(identical(first, second), true);
    });

    test('bump view invalidates cache', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      final first = db.sortedRows;
      db.setSearchQuery('Blue');
      final second = db.sortedRows;
      expect(identical(first, second), false);
      expect(second.length, 2);
    });
  });

  group('DatabaseProvider – widget rendering', () {
    testWidgets('search bar renders', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      expect(find.text('DATABASE'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('records found label shows correct count', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      expect(find.textContaining('5 records found'), findsOneWidget);
    });

    testWidgets('typing in search bar filters results', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Blue');
      await tester.pumpAndSettle();
      expect(find.textContaining('2 records found'), findsOneWidget);
    });

    testWidgets('clear button resets search', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Blue');
      await tester.pumpAndSettle();
      expect(find.textContaining('2 records found'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.textContaining('4 records found'), findsOneWidget);
    });

    testWidgets('clicking a row opens edit modal', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kind of Blue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kind of Blue'), findsWidgets);
    });

    testWidgets('group by dropdown is present', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsWidgets);
    });

    testWidgets('error state renders retry button', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider();
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('no back to search button in DB tab', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      expect(find.text('Back to Search'), findsNothing);
    });

    testWidgets('filter dropdown hidden when no query', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      expect(find.text('All fields'), findsNothing);
    });

    testWidgets('filter dropdown appears when query active', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Blue');
      await tester.pumpAndSettle();
      expect(find.text('All fields'), findsOneWidget);
    });

    testWidgets('filter dropdown filters to single column', (tester) async {
      await _useSurface(tester, const Size(1400, 900));
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      await tester.pumpWidget(_dbHost(db));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'spiritual');
      await tester.pumpAndSettle();
      final resultLabel = find.textContaining('A Love Supreme');
      expect(resultLabel, findsWidgets);
      final otherLabel = find.textContaining('Kind of Blue');
      expect(otherLabel, findsNothing);
    });

    test('hideShowColumns returns true', () {
      final db = DatabaseProvider();
      expect(db.hideShowColumns, true);
    });

    test('setSearchFilterField restricts fuzzy search to one column', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchFilterField('comments');
      db.setSearchQuery('spiritual jazz');
      expect(db.totalRows, 1);
      expect(db.sortedRows.first.record.recordName, 'A Love Supreme');
    });

    test('setSearchFilterField null searches all columns', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchFilterField('comments');
      db.setSearchQuery('Blue');
      expect(db.totalRows, 0);
      db.setSearchFilterField(null);
      db.setSearchQuery('Blue');
      expect(db.totalRows, 2);
    });

    test('clearSearch resets filter field', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchFilterField('name');
      db.setSearchQuery('Blue');
      expect(db.totalRows, 2);
      db.clearSearch();
      expect(db.searchFilterField, isNull);
      expect(db.searchQuery, '');
      expect(db.totalRows, 4);
    });

    test('usedGenreIds returns all genre IDs when no records loaded', () {
      final db = DatabaseProvider()
        ..allGenres = [
          Genre(genreId: 10, genreName: 'A'),
          Genre(genreId: 20, genreName: 'B'),
        ];
      expect(db.usedGenreIds, {10, 20});
    });

    test('usedGenreIds returns IDs from filtered records', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.usedGenreIds, {1, 2, 3, 4, 5});
    });

    test('usedDescriptorIds returns all descriptor IDs when no records loaded', () {
      final db = DatabaseProvider()
        ..allDescriptors = [
          Descriptor(descriptorId: 100, descriptorName: 'X'),
        ];
      expect(db.usedDescriptorIds, {100});
    });

    test('usedDescriptorIds returns IDs from filtered records', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.usedDescriptorIds, {1, 2, 3, 4, 5});
    });

    test('setBucket full-resets sort, group, filter, query', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setSearchQuery('Blue');
      db.setSearchFilterField('name');
      db.cycleSort('artists');
      db.setGroupBy('genres');
      db.setBucket(ResultBucket.finished);
      expect(db.searchQuery, '');
      expect(db.searchFilterField, isNull);
      expect(db.sortColumns, isEmpty);
      expect(db.groupByField, isNull);
    });

    test('filterFieldLabels has 9 entries', () {
      expect(DatabaseProvider.filterFieldLabels.length, 9);
    });

    test('cycleSort removing last sort leaves sortColumns empty', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      expect(db.sortColumns.length, 1);
      db.cycleSort('name');
      db.cycleSort('name');
      expect(db.sortColumns, isEmpty);
      expect(db.sortedRows.length, 5);
    });

    test('clearSorts after multi-sort leaves sortColumns empty', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.cycleSort('artists');
      expect(db.sortColumns.length, 2);
      db.clearSorts();
      expect(db.sortColumns, isEmpty);
    });

    test('sortedRows with empty sortColumns returns unsorted records', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.clearSorts();
      final names =
          db.sortedRows.map((r) => r.record.recordName).toList();
      expect(names.length, 5);
    });

    test('setBucket emptying sortColumns allows new sort from scratch', () {
      final db = DatabaseProvider()..presentRows(rows: _sampleRows());
      db.setBucket(ResultBucket.finished);
      expect(db.sortColumns, isEmpty);
      db.cycleSort('name');
      expect(db.sortColumns.length, 1);
      expect(db.sortColumns.first.field, 'name');
    });
  });
}
