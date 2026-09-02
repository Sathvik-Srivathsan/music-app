import 'package:music_collection/features/search/data/repositories/search_repository.dart';

/// Read side for the Statistics tab.
///
/// The Statistics feature reuses the existing single-load reconstruction
/// ([SearchRepository.fetchAllRecordDetails]) as its data source: all 7 chart
/// sections (Overview, Records, Artists, Genres, Descriptors, Streaming,
/// Relationships) aggregate over the same fully-joined rows. Keeping the repo
/// thin lets the aggregation logic stay in the pure, unit-tested
/// [StatisticsEngine].
class StatisticsRepository {
  final SearchRepository _searchRepo;

  StatisticsRepository({SearchRepository? searchRepository})
      : _searchRepo = searchRepository ?? SearchRepository();

  /// Loads every record fully reconstructed (record + artists/genres/
  /// descriptors/streaming) plus raw taxonomy hierarchy edges.
  Future<FetchResult> fetchAllData() => _searchRepo.fetchAllRecordDetails();
}
