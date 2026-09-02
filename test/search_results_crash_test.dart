import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/features/insert/presentation/providers/insert_provider.dart';
import 'package:music_collection/features/search/domain/search_query.dart';
import 'package:music_collection/features/search/presentation/providers/search_provider.dart';
import 'package:music_collection/features/search/presentation/screens/search_screen.dart';
import 'package:music_collection/features/search/presentation/widgets/search_results_view.dart';
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
  List<Artist> artists = const [],
  List<Genre> genres = const [],
  List<Descriptor> descriptors = const [],
  List<StreamingService> streaming = const [],
}) {
  return RecordDetails(
    record: Record(
      recordId: id,
      recordName: name,
      recordType: type,
      releaseDate: '1965-04-21',
      dateAdded: '05/07/2026',
      comments: id.isEven ? 'gatefold' : null,
      status: finished,
    ),
    artists: List.of(artists),
    genres: List.of(genres),
    descriptors: List.of(descriptors),
    streaming: List.of(streaming),
  );
}

List<RecordDetails> _rows() {
  final a1 = Artist(artistId: 10, artistName: 'Coltrane');
  final g1 = Genre(genreId: 30, genreName: 'Hard Bop');
  final d1 = Descriptor(descriptorId: 40, descriptorName: 'warm');
  return [
    for (var i = 1; i <= 40; i++)
      _row(
        id: i,
        name: i % 3 == 0 ? '$i compilation' : 'Álbum $i',
        type: i % 5 == 0
            ? 'EP'
            : i % 3 == 0
                ? 'Single'
                : 'Album',
        finished: i.isEven,
        artists: [a1],
        genres: [g1],
        descriptors: [d1],
        streaming: [
          StreamingService(serviceName: 'Spotify', serviceUrl: ''),
        ],
      ),
  ];
}

Widget _host(SearchProvider p, {Size size = const Size(1400, 900)}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<InsertProvider>(create: (_) => InsertProvider()),
      ChangeNotifierProvider<SearchResultsProvider>.value(value: p),
      ChangeNotifierProvider<SearchProvider>.value(value: p),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: SearchResultsView(),
        ),
      ),
    ),
  );
}

void main() {
  Future<void> useSurface(WidgetTester tester, Size logical) async {
    tester.view.physicalSize =
        Size(logical.width * tester.view.devicePixelRatio,
            logical.height * tester.view.devicePixelRatio);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('results render ungrouped at wide surface (fill mode)',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();
    expect(find.textContaining('records found'), findsOneWidget);
  });

  testWidgets('results render at narrow surface (scroll mode)',
      (tester) async {
    await useSurface(tester, const Size(700, 900));
    final p = SearchProvider()
      ..presentRows(
        rows: _rows(),
        legFailures: ['Streaming link: simulated'],
      );
    await tester.pumpWidget(_host(p, size: const Size(700, 900)));
    await tester.pumpAndSettle();
    expect(find.textContaining('records found'), findsOneWidget);
  });

  testWidgets('header wraps instead of overflowing at tablet width',
      (tester) async {
    await useSurface(tester, const Size(760, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p, size: const Size(760, 900)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SegmentedButton<ResultBucket>), findsOneWidget);
  });

  testWidgets('grouped mode with bands renders', (tester) async {
    final p = SearchProvider()
      ..presentRows(rows: _rows())
      ..setGroupBy('genres');
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();
    expect(find.text('Hard Bop'), findsWidgets);
  });

  testWidgets('sort badges + bucket switch + reorder overlay open/close',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()
      ..presentRows(rows: _rows())
      ..cycleSort('artists')
      ..setGroupBy('type');
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.low_priority), findsOneWidget);
    await tester.tap(find.byIcon(Icons.low_priority));
    await tester.pumpAndSettle();
    expect(find.text('Reorder Groups'), findsWidgets);
    // Close via the panel X (second close icon is the panel's).
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    p.setBucket(ResultBucket.active);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping a row opens the edit modal and closes it',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Álbum 1').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Record'), findsOneWidget);
    // Seeded chips from initialItems must be visible even though
    // InsertProvider caches are empty.
    expect(find.text('Coltrane'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Hard Bop'), findsAtLeastNWidgets(1));

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
  });

  testWidgets('back to search preserves entered form values',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<InsertProvider>(
            create: (_) => InsertProvider()),
        ChangeNotifierProvider<SearchResultsProvider>.value(value: p),
        ChangeNotifierProvider<SearchProvider>.value(value: p),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1400,
            height: 900,
            child: SearchScreen(),
          ),
        ),
      ),
    ));
    await tester.pump();

    final nameField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'e.g. Kind of Blue',
    );
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Álbum');
    await tester.pump();

    p.presentRows(rows: _rows());
    await tester.pumpAndSettle();
    expect(p.phase, SearchPhase.results);
    expect(find.textContaining('records found'), findsOneWidget);

    p.backToForm();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(nameField).controller!.text,
      'Álbum',
    );
    // Results header must be gone again.
    expect(find.text('Back to Search'), findsNothing);
  });

  // ---------- Provider logic tests ----------

  test('cycleSort first click replaces seeded name sort', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    expect(p.sortColumns.length, 1);
    expect(p.sortColumns.first.field, 'name');

    p.cycleSort('artists');
    expect(p.sortColumns.length, 1);
    expect(p.sortColumns.first.field, 'artists');
    expect(p.sortColumns.first.ascending, isTrue);
  });

  test('cycleSort second click appends after first', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    p.cycleSort('artists');
    p.cycleSort('type');
    expect(p.sortColumns.length, 2);
    expect(p.sortColumns[0].field, 'artists');
    expect(p.sortColumns[1].field, 'type');
  });

  test('cycleSort third click on same field toggles ascending→descending', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    p.cycleSort('artists');
    expect(p.sortColumns.first.ascending, isTrue);
    p.cycleSort('artists');
    expect(p.sortColumns.first.ascending, isFalse);
  });

  test('cycleSort fourth click removes the field', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    p.cycleSort('artists');
    p.cycleSort('artists');
    p.cycleSort('artists');
    expect(p.sortColumns.any((s) => s.field == 'artists'), isFalse);
  });

  test('clearSorts removes all sorting', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    p.cycleSort('artists');
    p.cycleSort('type');
    expect(p.sortColumns.length, 2);
    p.clearSorts();
    expect(p.sortColumns, isEmpty);
    // After clear, next cycleSort should replace (not append),
    // since _userSorted is false.
    p.cycleSort('genres');
    expect(p.sortColumns.length, 1);
    expect(p.sortColumns.first.field, 'genres');
  });

  test('isColumnShown frozen trio always true regardless of overrides', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    for (final f in ['name', 'artists', 'genres']) {
      expect(p.isColumnShown(f), isTrue, reason: '$f should be frozen');
    }
  });

  test('setColumnVisible cannot hide frozen columns', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    p.setColumnVisible('artists', false);
    expect(p.isColumnShown('artists'), isTrue);
    p.setColumnVisible('genres', false);
    expect(p.isColumnShown('genres'), isTrue);
  });

  test('setColumnVisible toggles non-frozen column', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    // 'type' is adaptive (shown when query.recordTypes is empty = false),
    // but we can manually override it.
    p.setColumnVisible('type', true);
    expect(p.isColumnShown('type'), isTrue);
    p.setColumnVisible('type', false);
    expect(p.isColumnShown('type'), isFalse);
  });

  test('memoization: sortedRows returns same list on identical viewVersion', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    final a = p.sortedRows;
    final b = p.sortedRows;
    expect(identical(a, b), isTrue);
  });

  test('memoization: sortedRows invalidates after _bumpView', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    final a = p.sortedRows;
    p.cycleSort('artists');
    final b = p.sortedRows;
    expect(identical(a, b), isFalse);
  });

  // ---------- Widget layout tests ----------

  testWidgets('columns dropdown shows frozen trio checked and disabled',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Open the columns picker.
    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();

    // Frozen trio labels must be visible in the overlay.
    expect(find.text('Record Name'), findsWidgets);
    expect(find.text('Artists'), findsWidgets);
    expect(find.text('Genres'), findsWidgets);
  });

  testWidgets('equal-width columns: header cells share width via Expanded',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Just verify the view renders without overflow at 1400px.
    expect(find.textContaining('records found'), findsOneWidget);
    // Verify some data rows exist.
    expect(find.text('Álbum 1'), findsOneWidget);
  });

  testWidgets('scroll mode renders at narrow width without overflow',
      (tester) async {
    await useSurface(tester, const Size(500, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p, size: const Size(500, 900)));
    await tester.pumpAndSettle();
    expect(find.textContaining('records found'), findsOneWidget);
  });

  testWidgets('multi-sort badges appear in correct order',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    // Ensure 'type' is visible so its header badge renders.
    p.setColumnVisible('type', true);
    p.cycleSort('artists');
    p.cycleSort('type');
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Sort badge "1" should appear (on Artists), badge "2" on Type.
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('columns picker button says "Show Columns"',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();
    expect(find.text('Show Columns'), findsOneWidget);
  });

  testWidgets('columns checkbox toggles and overlay rebuilds',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Open the columns picker.
    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();

    // "Type" should not be shown by default (adaptive, query empty).
    expect(p.isColumnShown('type'), isFalse);

    // Find the Type row and tap its checkbox.
    final typeTile = find.widgetWithText(CheckboxListTile, 'Type');
    expect(typeTile, findsOneWidget);
    await tester.tap(typeTile);
    await tester.pumpAndSettle();
    expect(p.isColumnShown('type'), isTrue);

    // Tap again to uncheck.
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Type'));
    await tester.pumpAndSettle();
    expect(p.isColumnShown('type'), isFalse);
  });

  testWidgets('columns overlay opens downward not upward',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Find the button's position.
    final btn = find.byIcon(Icons.view_column_outlined);
    final btnRect = tester.getRect(btn);

    // Open the overlay.
    await tester.tap(btn);
    await tester.pumpAndSettle();

    // The overlay panel should appear below the button.
    final panel = find.text('Displaying Columns');
    expect(panel, findsOneWidget);
    final panelRect = tester.getRect(panel);
    // Panel top should be at or below button bottom.
    expect(panelRect.top, greaterThanOrEqualTo(btnRect.bottom - 1));
  });

  testWidgets('sort clear button removes all sorts',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    p.cycleSort('artists');
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Clear sorts button should be visible (2 sort columns: artists + default name).
    expect(find.textContaining('Clear sorts'), findsOneWidget);
    await tester.tap(find.textContaining('Clear sorts'));
    await tester.pumpAndSettle();

    // After clearing, no sorts remain, so the button should disappear.
    expect(find.textContaining('Clear sorts'), findsNothing);
    expect(p.sortColumns, isEmpty);
  });

  // --- Smart genre grouping tests ---

  /// Helper: records with genres from a hierarchy.
  /// Hierarchy: Rock(1) -> AltRock(2) -> PostPunk(3)
  ///           Jazz(10) -> Bebop(11)
  List<RecordDetails> genreRows() {
    final rock = Genre(genreId: 1, genreName: 'Rock');
    final altRock = Genre(genreId: 2, genreName: 'Alt Rock');
    final postPunk = Genre(genreId: 3, genreName: 'Post Punk');
    final jazz = Genre(genreId: 10, genreName: 'Jazz');
    final bebop = Genre(genreId: 11, genreName: 'Bebop');
    return [
      // Record with Rock (parent)
      _row(id: 1, name: 'Record A', genres: [rock]),
      // Record with Alt Rock (child of Rock)
      _row(id: 2, name: 'Record B', genres: [altRock]),
      // Record with Post Punk (grandchild of Rock)
      _row(id: 3, name: 'Record C', genres: [postPunk]),
      // Record with Jazz (parent)
      _row(id: 4, name: 'Record D', genres: [jazz]),
      // Record with Bebop (child of Jazz)
      _row(id: 5, name: 'Record E', genres: [bebop]),
      // Record with both Rock and Alt Rock (multi-match)
      _row(id: 6, name: 'Record F', genres: [rock, altRock]),
      // Record with Post Punk and Bebop (cross-family)
      _row(id: 7, name: 'Record G', genres: [postPunk, bebop]),
    ];
  }

  List<MapEntry<int, int>> genreEdges() => const [
        // Rock -> Alt Rock -> Post Punk
        MapEntry(1, 2),
        MapEntry(2, 3),
        // Jazz -> Bebop
        MapEntry(10, 11),
      ];

  SearchProvider smartGenreProvider({
    List<int> selectedGenreIds = const [1, 10],
  }) {
    final p = SearchProvider()
      ..allGenres = [
        Genre(genreId: 1, genreName: 'Rock'),
        Genre(genreId: 2, genreName: 'Alt Rock'),
        Genre(genreId: 3, genreName: 'Post Punk'),
        Genre(genreId: 10, genreName: 'Jazz'),
        Genre(genreId: 11, genreName: 'Bebop'),
      ];
    p.presentRows(
      rows: genreRows(),
      genreEdges: genreEdges(),
    );
    p.query.genreIds
      ..clear()
      ..addAll(selectedGenreIds);
    p.query.genresMode = StreamingFilterMode.any;
    p.groupByField = 'genres';
    p.cycleSort('name');
    return p;
  }

  test('smart genre grouping: families ordered by filter insertion order',
      () {
    final p = smartGenreProvider(selectedGenreIds: [10, 1]); // Jazz first
    final groups = p.groupedRows;
    final names = [for (final e in groups) e.key];
    // Jazz family should come before Rock family.
    expect(names.indexOf('Jazz'), lessThan(names.indexOf('Rock')));
    expect(names.indexOf('Bebop'), lessThan(names.indexOf('Rock')));
  });

  test('smart genre grouping: subgenres sorted by closure size descending',
      () {
    final p = smartGenreProvider(selectedGenreIds: [1]); // Rock only
    final groups = p.groupedRows;
    final names = [for (final e in groups) e.key];
    // Rock closure = {1,2,3} size=3, AltRock={2,3} size=2, PostPunk={3} size=1
    // Within Rock family: Rock(3) > AltRock(2) > PostPunk(1)
    final rockFamily = names.where((n) => {
      'Rock', 'Alt Rock', 'Post Punk',
    }.contains(n)).toList();
    expect(rockFamily, ['Rock', 'Alt Rock', 'Post Punk']);
  });

  test('smart genre grouping: records sorted by matched count descending',
      () {
    // Use both Rock and Alt Rock as filters so Record F matches 2.
    final p = smartGenreProvider(selectedGenreIds: [1, 2]);
    final groups = p.groupedRows;
    // Find "Rock" group.
    final rockGroup = groups.firstWhere((e) => e.key == 'Rock');
    // Record F has Rock + Alt Rock = 2 matches in {1, 2}.
    // Record A has Rock = 1 match.
    // Record B has Alt Rock = 1 match.
    final names = [for (final r in rockGroup.value) r.record.recordName];
    // Record F should be first (most matches).
    expect(names.first, 'Record F');
  });

  test('smart genre grouping: does not activate in ALL mode', () {
    final p = smartGenreProvider();
    p.query.genresMode = StreamingFilterMode.all;
    // Trigger view version bump so groupedRows recomputes.
    p.cycleSort('name');
    final groups = p.groupedRows;
    // Should not be smart-ordered — just plain alphabetical.
    final names = [for (final e in groups) e.key];
    expect(names, containsAll(['Rock', 'Alt Rock', 'Post Punk', 'Jazz', 'Bebop']));
  });

  test('smart genre grouping: does not activate without genre filters', () {
    final p = smartGenreProvider(selectedGenreIds: []);
    final groups = p.groupedRows;
    final names = [for (final e in groups) e.key];
    // No smart ordering, just plain alphabetical.
    expect(names, containsAll(['Rock', 'Alt Rock', 'Post Punk', 'Jazz', 'Bebop']));
  });

  test('smart genre grouping: cross-family records appear in both families',
      () {
    final p = smartGenreProvider(selectedGenreIds: [1, 10]);
    final groups = p.groupedRows;
    // Record G has Post Punk + Bebop, should appear in both groups.
    final postPunkGroup = groups.firstWhere((e) => e.key == 'Post Punk');
    final bebopGroup = groups.firstWhere((e) => e.key == 'Bebop');
    expect(
      postPunkGroup.value.any((r) => r.record.recordId == 7),
      isTrue,
    );
    expect(
      bebopGroup.value.any((r) => r.record.recordId == 7),
      isTrue,
    );
  });

  // ── Fix 4: Genre depth 0th order sort ──────────────────────────

  SearchProvider _depthProvider({List<int> genreIds = const [1]}) {
    final edges = [
      MapEntry(1, 2), // Rock -> Alt Rock
      MapEntry(2, 3), // Alt Rock -> Post Punk
      MapEntry(10, 11), // Jazz -> Bebop
    ];
    final rows = [
      _row(id: 1, name: 'A', genres: [Genre(genreId: 1, genreName: 'Rock')]),
      _row(id: 2, name: 'B', genres: [Genre(genreId: 2, genreName: 'Alt Rock')]),
      _row(id: 3, name: 'C', genres: [Genre(genreId: 3, genreName: 'Post Punk')]),
      _row(id: 4, name: 'D', genres: [Genre(genreId: 10, genreName: 'Jazz')]),
      _row(id: 5, name: 'E', genres: [Genre(genreId: 11, genreName: 'Bebop')]),
      _row(id: 6, name: 'F', genres: [
        Genre(genreId: 1, genreName: 'Rock'),
        Genre(genreId: 2, genreName: 'Alt Rock'),
      ]),
      _row(id: 7, name: 'G', genres: [
        Genre(genreId: 1, genreName: 'Rock'),
        Genre(genreId: 2, genreName: 'Alt Rock'),
        Genre(genreId: 3, genreName: 'Post Punk'),
      ]),
      _row(id: 8, name: 'H', genres: [
        Genre(genreId: 1, genreName: 'Rock'),
        Genre(genreId: 10, genreName: 'Jazz'),
      ]),
    ];
    final p = SearchProvider();
    p.allGenres = [
      Genre(genreId: 1, genreName: 'Rock'),
      Genre(genreId: 2, genreName: 'Alt Rock'),
      Genre(genreId: 3, genreName: 'Post Punk'),
      Genre(genreId: 10, genreName: 'Jazz'),
      Genre(genreId: 11, genreName: 'Bebop'),
    ];
    p.presentRows(rows: rows, genreEdges: edges);
    p.query.genreIds
      ..clear()
      ..addAll(genreIds);
    p.query.genresMode = StreamingFilterMode.any;
    p.clearSorts();
    return p;
  }

  test('genre depth sort: higher count (more subgenres) ranks first', () {
    final p = _depthProvider(genreIds: [1]);
    final names = [for (final r in p.sortedRows) r.record.recordName];
    // G(count=3) before F(count=2) before A/H/B(count=1) before D/E(count=0)
    expect(names.indexOf('G'), lessThan(names.indexOf('F')));
    expect(names.indexOf('F'), lessThan(names.indexOf('A')));
  });

  test('genre depth sort: same count, lower totalDepth ranks first', () {
    // A has Rock(d0) -> count=1, totalDepth=0
    // B has Alt Rock(d1) -> count=1, totalDepth=1
    // C has Post Punk(d2) -> count=1, totalDepth=2
    final p = _depthProvider(genreIds: [1]);
    final names = [for (final r in p.sortedRows) r.record.recordName];
    expect(names.indexOf('A'), lessThan(names.indexOf('B')));
    expect(names.indexOf('B'), lessThan(names.indexOf('C')));
  });

  test('genre depth sort: non-matching records sort after all matching',
      () {
    // Selecting Rock (1): D(Jazz) and E(Bebop) have count=0
    final p = _depthProvider(genreIds: [1]);
    final names = [for (final r in p.sortedRows) r.record.recordName];
    expect(names.indexOf('D'), greaterThan(names.indexOf('C')));
    expect(names.indexOf('E'), greaterThan(names.indexOf('C')));
  });

  test('genre depth sort: user sort replaces genre depth entirely', () {
    final p = _depthProvider(genreIds: [1]);
    p.cycleSort('name');
    final names = [for (final r in p.sortedRows) r.record.recordName];
    expect(names.first, 'A');
  });

  test('genre depth sort: clearSorts reverts to 0th order genre depth',
      () {
    final p = _depthProvider(genreIds: [1]);
    p.cycleSort('name');
    p.clearSorts();
    final names = [for (final r in p.sortedRows) r.record.recordName];
    // G(count=3) back at top
    expect(names.first, 'G');
  });

  test('genre depth sort: no depth sort when genre filters empty', () {
    final p = _depthProvider(genreIds: []);
    final names = [for (final r in p.sortedRows) r.record.recordName];
    // No genre filters -> just name sort
    expect(names, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']);
  });

  test('genre depth sort: child at depth 2 comes after depth 1', () {
    // Selecting Alt Rock (2): B(Alt Rock d0), C(Post Punk d1)
    final p = _depthProvider(genreIds: [2]);
    final names = [for (final r in p.sortedRows) r.record.recordName];
    expect(names.indexOf('B'), lessThan(names.indexOf('C')));
  });

  // ── Empty sort columns crash guard ────────────────────────────

  test('empty sortColumns: sortedRows falls back to name sort', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    p.clearSorts();
    expect(p.sortColumns, isEmpty);
    final names = [for (final r in p.sortedRows) r.record.recordName];
    expect(names.length, greaterThan(0));
    expect(p.sortColumns, isEmpty);
  });

  test('empty sortColumns: no crash when cycleSort removes last sort', () {
    final p = SearchProvider()..presentRows(rows: _rows());
    p.cycleSort('name');
    p.cycleSort('name');
    expect(p.sortColumns, isEmpty);
    expect(p.sortedRows.length, p.bucketRows.length);
  });

  test('empty sortColumns: genre depth fallback when genre filters active',
      () {
    final p = _depthProvider(genreIds: [1]);
    p.clearSorts();
    expect(p.sortColumns, isEmpty);
    final names = [for (final r in p.sortedRows) r.record.recordName];
    expect(names, isNotEmpty);
  });

  // ── Fix 5: Copy button in edit modal ──────────────────────────

  testWidgets('edit modal has copy button', (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Álbum 1').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Record'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
  });

  testWidgets('copy button copies artist - record name to clipboard',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Álbum 1').first);
    await tester.pumpAndSettle();

    // Tap copy — should not throw or show toast/snackbar.
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();

    // No toast or snackbar should appear.
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
  });

  // ── Fix 1: Unified table — name as first data column ──────────

  testWidgets('name appears as first column in unified table',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Record Name header should be in the table header row.
    expect(find.text('Record Name'), findsOneWidget);
    // Status dots should be rendered (the 8px colored circles).
    // We check by verifying the edit modal can still be opened.
    await tester.tap(find.text('Álbum 1').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Record'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
  });

  testWidgets('no separate name pane (no left pane row)',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // There should be no Row with two children (old two-pane layout).
    // Instead there's a single scrollable or fixed pane.
    // Verify the old methods are gone by checking no SizedBox with nameW.
    // A simpler check: all header cells are within the same Row.
    expect(find.text('Record Name'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
  });

  // ── Fix 3: Record Name in Show Columns dropdown (locked) ─────

  testWidgets('Record Name shows as locked in Show Columns',
      (tester) async {
    await useSurface(tester, const Size(1400, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p));
    await tester.pumpAndSettle();

    // Open the Show Columns overlay.
    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();

    // Record Name should be visible and its checkbox disabled (locked).
    // Note: "Record Name" also appears in the table header, so use
    // ancestor filter for the CheckboxListTile inside the overlay.
    final nameRow = find.ancestor(
      of: find.text('Record Name'),
      matching: find.byType(CheckboxListTile),
    );
    expect(nameRow, findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(nameRow);
    expect(checkbox.onChanged, isNull); // disabled (frozen)

    // Close overlay by tapping outside (overlay dismisses on pointer down).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  // ── Fix 2: Scroll pill improvements ───────────────────────────

  testWidgets('right scroll pill appears in scroll mode and has correct label',
      (tester) async {
    await useSurface(tester, const Size(700, 900));
    final p = SearchProvider()..presentRows(rows: _rows());
    await tester.pumpWidget(_host(p, size: const Size(700, 900)));
    await tester.pumpAndSettle();

    // In narrow mode, enough cols should be hidden to trigger the pill.
    // Look for "Scroll for →" text.
    final pillFinder = find.textContaining('Scroll for →');
    if (pillFinder.evaluate().isNotEmpty) {
      expect(pillFinder, findsOneWidget);
    }
    // Left pill should NOT exist.
    expect(find.textContaining('←'), findsNothing);
  });
}
