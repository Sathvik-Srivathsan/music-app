import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/search/data/repositories/search_repository.dart';
import 'package:music_collection/features/statistics/data/repositories/audit_log_repository.dart';
import 'package:music_collection/features/statistics/data/repositories/statistics_repository.dart';
import 'package:music_collection/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:music_collection/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/audit_log.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';
import 'package:provider/provider.dart';

class _FakeRepo extends StatisticsRepository {
  final List<RecordDetails> rows;
  int loadCount = 0;

  _FakeRepo({required this.rows});

  @override
  Future<FetchResult> fetchAllData() async {
    loadCount++;
    return FetchResult(rows, const []);
  }
}

class _FakeLogRepo extends AuditLogRepository {
  int logLoadCount = 0;

  @override
  Future<AuditLogPage> fetchPage({
    String? action,
    String? table,
    String? search,
    required int page,
    int pageSize = 50,
  }) async {
    logLoadCount++;
    return AuditLogPage(
      rows: [
        AuditLog(
          logId: 1,
          action: 'insert',
          tableName: 'records',
          details: {
            'inserted': {
              'record_name': 'Test Record',
              'record_type': 'Album',
              'status': 'false',
            },
          },
          originTab: 'insert',
          device: 'web',
        ),
      ],
    );
  }
}

RecordDetails _row({
  required int id,
  required String name,
  bool finished = false,
  String? type = 'Album',
  String? releaseDate = '1965-04-21',
  List<String> artists = const ['Artist'],
  List<String> genres = const ['Jazz'],
  List<String> streaming = const ['Spotify'],
}) {
  return RecordDetails(
    record: Record(
      recordId: id,
      recordName: name,
      recordType: type,
      releaseDate: releaseDate,
      dateAdded: '05/07/2026',
      status: finished,
    ),
    artists: [for (final a in artists) Artist(artistId: id * 10, artistName: a)],
    genres: [for (final g in genres) Genre(genreId: id * 10, genreName: g)],
    descriptors: [
      Descriptor(descriptorId: 1, descriptorName: 'Classic'),
    ],
    streaming: [
      for (final s in streaming) StreamingService(serviceName: s, serviceUrl: 'u'),
    ],
  );
}

Widget _host(StatisticsProvider provider) {
  return ChangeNotifierProvider<StatisticsProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: StatisticsScreen(),
    ),
  );
}

void main() {
  testWidgets('renders overview headlines and default-expanded overview section',
      (tester) async {
    final repo = _FakeRepo(rows: [
      _row(id: 1, name: 'A', releaseDate: '1965'),
      _row(id: 2, name: 'B', finished: true, releaseDate: '1970'),
    ]);
    final provider = StatisticsProvider(repository: repo);
    await tester.pumpWidget(_host(provider));
    await provider.load();
    await tester.pumpAndSettle();

    expect(repo.loadCount, 1);
    expect(find.text('STATISTICS'), findsOneWidget);
    // Overview section is expanded by default -> headline cards visible.
    expect(find.text('Records'), findsWidgets);
    expect(find.text('2'), findsWidgets); // total records headline
    // The status pie is a collapsed chart -> its legend is not rendered yet.
    expect(find.textContaining('Active ('), findsNothing);
  });

  testWidgets('collapsible chart only renders after being expanded',
      (tester) async {
    final repo = _FakeRepo(rows: [
      _row(id: 1, name: 'A'),
      _row(id: 2, name: 'B', finished: true),
    ]);
    final provider = StatisticsProvider(repository: repo);
    await tester.pumpWidget(_host(provider));
    await provider.load();
    await tester.pumpAndSettle();

    // Status pie is a collapsed chart -> its legend label not present.
    expect(find.text('Records by status'), findsOneWidget);
    expect(find.textContaining('Active ('), findsNothing);

    // Expand the status chart card.
    await tester.ensureVisible(find.text('Records by status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Records by status'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Active ('), findsOneWidget);
  });

  testWidgets('Log sub-tab renders the audit-log viewer with rows',
      (tester) async {
    final repo = _FakeRepo(rows: [
      _row(id: 1, name: 'A'),
    ]);
    final logRepo = _FakeLogRepo();
    final provider = StatisticsProvider(
      repository: repo,
      auditLogRepository: logRepo,
    );
    await tester.pumpWidget(_host(provider));
    await provider.load();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    expect(logRepo.logLoadCount, greaterThan(0));
    // The viewer renders the human sentence for the record insert.
    expect(find.textContaining('Added record "Test Record"'),
        findsOneWidget);
    // The refresh button and pagination are present.
    expect(find.byTooltip('Refresh audit log'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.byTooltip('First page'), findsOneWidget);
    expect(find.byTooltip('Previous page'), findsOneWidget);
    expect(find.byTooltip('Next page'), findsOneWidget);

    // Table-style headers (DB-tab look) are rendered.
    for (final header in ['Time', 'Action', 'Table', 'Origin', 'Device', 'Details']) {
      expect(find.text(header), findsAtLeastNWidgets(1),
          reason: 'log table should show a $header column header');
    }

    // Infoboxes (info tips) exist for the columns and the filter hints.
    expect(find.byIcon(Icons.info_outline), findsWidgets);

    // Back to charts keeps working.
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('STATISTICS'), findsOneWidget);
  });
}
