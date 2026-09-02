import 'package:flutter/foundation.dart';
import 'package:music_collection/features/search/domain/search_query.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/features/search/presentation/providers/search_provider.dart';

abstract class SearchResultsProvider extends ChangeNotifier {
  List<RecordDetails> get sortedRows;
  List<RecordDetails> get bucketRows;
  List<RecordDetails> get activeResults;
  List<RecordDetails> get finishedResults;
  int get totalRows;

  ResultBucket get currentBucket;
  void setBucket(ResultBucket bucket);

  SearchQueryParams get query;

  List<SortColumn> get sortColumns;
  void cycleSort(String field);
  void clearSorts();
  int sortPriority(String field);

  String? get groupByField;
  void setGroupBy(String? field);
  List<MapEntry<String, List<RecordDetails>>> get groupedRows;
  void reorderGroups(List<String> orderedKeys);
  Map<String, int> get groupOrderOverride;

  bool isColumnShown(String field);
  void setColumnVisible(String field, bool shown);

  // DB tab only — null means no filter (search all fields)
  String? get searchFilterField => null;
  void setSearchFilterField(String? field) {}

  // DB tab only — hides the Show Columns picker button
  bool get hideShowColumns => false;

  List<Artist> get allArtists;
  List<Genre> get allGenres;
  List<Descriptor> get allDescriptors;
  double fuzzyMatch(String queryText, String target);

  Future<String?> saveEdits(RecordDetails edited, {String originTab = 'search'});
  Future<String?> deleteById(int recordId, {String originTab = 'search'});
  Future<void> loadEntities();
}
