import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/network/supabase_client.dart';
import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/streaming_service.dart';

class InsertRepository {
  static const int _pageSize = 1000;

  Future<List<dynamic>> _fetchAllPaginated({
    required String table,
    required String orderColumn,
  }) async {
    final all = <dynamic>[];
    var from = 0;
    while (true) {
      final page = await SupabaseService.from(table).select() //
          .order(orderColumn)
          .range(from, from + _pageSize - 1);
      final rows = page as List;
      all.addAll(rows);
      if (rows.length < _pageSize) break;
      from += _pageSize;
    }
    return all;
  }

  // --- Artists ---
  Future<List<Artist>> fetchAllArtists() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableArtists, orderColumn: 'artist_name');
    return data.map((e) => Artist.fromJson(e)).toList();
  }

  Future<Artist?> findArtistByName(String name) async {
    final data = await SupabaseService.from(AppConstants.tableArtists)
        .select()
        .eq('artist_name', name)
        .maybeSingle();
    return data != null ? Artist.fromJson(data) : null;
  }

  Future<Artist> createArtist(String name, {String originTab = 'insert'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableArtists, originTab)
        .insert({'artist_name': name})
        .select()
        .single();
    return Artist.fromJson(data);
  }

  // --- Genres ---
  Future<List<Genre>> fetchAllGenres() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableGenres, orderColumn: 'genre_name');
    return data.map((e) => Genre.fromJson(e)).toList();
  }

  Future<Genre?> findGenreByName(String name) async {
    final data = await SupabaseService.from(AppConstants.tableGenres)
        .select()
        .eq('genre_name', name)
        .maybeSingle();
    return data != null ? Genre.fromJson(data) : null;
  }

  Future<Genre> createGenre(String name, {String originTab = 'insert'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableGenres, originTab)
        .insert({'genre_name': name})
        .select()
        .single();
    return Genre.fromJson(data);
  }

  // --- Descriptors ---
  Future<List<Descriptor>> fetchAllDescriptors() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableDescriptors, orderColumn: 'descriptor_name');
    return data.map((e) => Descriptor.fromJson(e)).toList();
  }

  Future<Descriptor?> findDescriptorByName(String name) async {
    final data = await SupabaseService.from(AppConstants.tableDescriptors)
        .select()
        .eq('descriptor_name', name)
        .maybeSingle();
    return data != null ? Descriptor.fromJson(data) : null;
  }

  Future<Descriptor> createDescriptor(String name,
      {String originTab = 'insert'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableDescriptors, originTab)
        .insert({'descriptor_name': name})
        .select()
        .single();
    return Descriptor.fromJson(data);
  }

  // --- Records ---
  Future<Record> insertRecord({
    required String recordName,
    String? recordType,
    String? releaseDate,
    String? comments,
    required bool status,
    String originTab = 'insert',
  }) async {
    final now = DateTime.now();
    final dateAdded =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final canonical = canonicalizeReleaseDate(releaseDate);
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableRecords, originTab)
        .insert({
          'record_name': recordName,
          'record_type': recordType,
          'release_date': canonical.iso,
          'release_date_mask': canonical.mask,
          'comments': comments,
          'status': status,
          'date_added': dateAdded,
        })
        .select()
        .single();
    return Record.fromJson(data);
  }

  // --- Junction Tables ---
  Future<void> insertRecordArtists(
      int recordId, List<Artist> artists,
      {String originTab = 'insert'}) async {
    if (artists.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < artists.length; i++) {
      rows.add({
        'record_id': recordId,
        'artist_id': artists[i].artistId,
        'artist_order': i + 1,
      });
    }
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordArtists, originTab)
        .insert(rows);
  }

  Future<void> insertRecordGenres(int recordId, List<Genre> genres,
      {String originTab = 'insert'}) async {
    if (genres.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < genres.length; i++) {
      rows.add({
        'record_id': recordId,
        'genre_id': genres[i].genreId,
        'genre_order': i + 1,
      });
    }
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordGenres, originTab)
        .insert(rows);
  }

  Future<void> insertRecordDescriptors(
      int recordId, List<Descriptor> descriptors,
      {String originTab = 'insert'}) async {
    if (descriptors.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < descriptors.length; i++) {
      rows.add({
        'record_id': recordId,
        'descriptor_id': descriptors[i].descriptorId,
        'descriptor_order': i + 1,
      });
    }
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordDescriptors, originTab)
        .insert(rows);
  }

  Future<void> insertRecordStreaming(
      int recordId, List<StreamingService> services,
      {String originTab = 'insert'}) async {
    if (services.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (final s in services) {
      rows.add({
        'record_id': recordId,
        'service_name': s.serviceName,
        'service_url': s.serviceUrl,
      });
    }
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordStreaming, originTab)
        .insert(rows);
  }

  // --- Audit Log ---
  Future<void> logAction({
    required String action,
    required String tableName,
    int? recordId,
    Map<String, dynamic>? details,
  }) async {
    await SupabaseService.from(AppConstants.tableAuditLog).insert({
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'details': details,
    });
  }

  // --- Full Insert (transaction-like) ---
  Future<Record> insertFullRecord({
    required String recordName,
    required List<Artist> artists,
    required List<Genre> genres,
    required List<Descriptor> descriptors,
    String? recordType,
    String? releaseDate,
    String? comments,
    required bool status,
    required List<StreamingService> streamingServices,
    String originTab = 'insert',
  }) async {
    final record = await insertRecord(
      recordName: recordName,
      recordType: recordType,
      releaseDate: releaseDate,
      comments: comments,
      status: status,
      originTab: originTab,
    );

    final recordId = record.recordId!;
    await insertRecordArtists(recordId, artists, originTab: originTab);
    await insertRecordGenres(recordId, genres, originTab: originTab);
    await insertRecordDescriptors(recordId, descriptors, originTab: originTab);
    await insertRecordStreaming(recordId, streamingServices,
        originTab: originTab);

    return record;
  }
}
