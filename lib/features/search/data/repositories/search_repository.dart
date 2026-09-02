import 'package:flutter/foundation.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/network/supabase_client.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';

/// Outcome of a full reconstruction. A failure in any relation other
/// than the core records read is non-fatal: rows still render with
/// that relation empty, and [legFailures] names the broken legs.
class FetchResult {
  final List<RecordDetails> rows;
  final List<String> legFailures;

  /// Raw parent->child taxonomy edges (parent id key, child id value)
  /// powering hierarchy-aware filtering. Empty when those legs fail.
  final List<MapEntry<int, int>> genreEdges;
  final List<MapEntry<int, int>> descriptorEdges;

  const FetchResult(
    this.rows,
    this.legFailures, {
    this.genreEdges = const [],
    this.descriptorEdges = const [],
  });

  bool get hasLegFailures => legFailures.isNotEmpty;
}

/// Read side: full reconstruction of every record (row + joined
/// entities). Write side: update / status / delete used by the edit
/// popup. All list reads page through the PostgREST 1000-row cap.
class SearchRepository {
  static const int _pageSize = 1000;

  Future<List<Map<String, dynamic>>> _paginated({
    required String table,
    String select = '*',
    String? order,
  }) async {
    final all = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = await (order == null
              ? SupabaseService.from(table)
                  .select(select)
                  .range(from, from + _pageSize - 1)
              : SupabaseService.from(table)
                  .select(select)
                  .order(order)
                  .range(from, from + _pageSize - 1));
      final rows = (page as List).cast<Map<String, dynamic>>();
      all.addAll(rows);
      if (rows.length < _pageSize) break;
      from += _pageSize;
    }
    return all;
  }

  Future<FetchResult> fetchAllRecordDetails() async {
    final legFailures = <String>[];

    List<Map<String, dynamic>> records;
    try {
      records = await _paginated(
          table: AppConstants.tableRecords, order: 'record_id');
    } catch (e) {
      // Core read dead: nothing can render, surface everything.
      throw StateError('Core records read failed: $e');
    }

    Future<List<Map<String, dynamic>>> leg(
        String name, Future<List<Map<String, dynamic>>> Function() f) async {
      try {
        return await f();
      } catch (e) {
        debugPrint('$name link fetch failed: $e');
        legFailures.add('$name: $e');
        return const [];
      }
    }

    final raRows = await leg('Artists link', () => _paginated(
      table: AppConstants.tableRecordArtists,
      select: 'record_id,artist_order,artists(artist_id,artist_name)',
      order: 'record_id',
    ));
    final rgRows = await leg('Genres link', () => _paginated(
      table: AppConstants.tableRecordGenres,
      select: 'record_id,genre_order,genres(genre_id,genre_name)',
      order: 'record_id',
    ));
    final rdRows = await leg('Descriptors link', () => _paginated(
      table: AppConstants.tableRecordDescriptors,
      select:
          'record_id,descriptor_order,descriptors(descriptor_id,descriptor_name)',
      order: 'record_id',
    ));
    final rsRows = await leg('Streaming link', () => _paginated(
        table: AppConstants.tableRecordStreaming, order: 'record_id'));
    final ghRows = await leg('Genre hierarchy', () => _paginated(
        table: AppConstants.tableGenreHierarchy, order: 'parent_genre_id'));
    final dhRows = await leg('Descriptor hierarchy', () => _paginated(
        table: AppConstants.tableDescriptorHierarchy,
        order: 'parent_descriptor_id'));

    final artistsBy = <int, List<MapEntry<int, Artist>>>{};
    for (final row in raRows) {
      final embedded = row['artists'];
      if (embedded == null) continue;
      try {
        (artistsBy[row['record_id'] as int] ??= []).add(MapEntry(
          row['artist_order'] as int? ?? 0,
          Artist.fromJson(embedded as Map<String, dynamic>),
        ));
      } catch (e) {
        legFailures.add(
            'Artist link row skipped (record ${row['record_id']}): $e');
      }
    }

    final genresBy = <int, List<MapEntry<int, Genre>>>{};
    for (final row in rgRows) {
      final embedded = row['genres'];
      if (embedded == null) continue;
      try {
        (genresBy[row['record_id'] as int] ??= []).add(MapEntry(
          row['genre_order'] as int? ?? 0,
          Genre.fromJson(embedded as Map<String, dynamic>),
        ));
      } catch (e) {
        legFailures.add(
            'Genre link row skipped (record ${row['record_id']}): $e');
      }
    }

    final descriptorsBy = <int, List<MapEntry<int, Descriptor>>>{};
    for (final row in rdRows) {
      final embedded = row['descriptors'];
      if (embedded == null) continue;
      try {
        (descriptorsBy[row['record_id'] as int] ??= []).add(MapEntry(
          row['descriptor_order'] as int? ?? 0,
          Descriptor.fromJson(embedded as Map<String, dynamic>),
        ));
      } catch (e) {
        legFailures.add(
            'Descriptor link row skipped '
            '(record ${row['record_id']}): $e');
      }
    }

    final streamingBy = <int, List<StreamingService>>{};
    for (final row in rsRows) {
      try {
        (streamingBy[row['record_id'] as int] ??= [])
            .add(StreamingService.fromJson(row));
      } catch (e) {
        legFailures.add('Streaming row skipped '
            '(record ${row['record_id']}): $e');
      }
    }

    final genreEdges = <MapEntry<int, int>>[];
    for (final row in ghRows) {
      final p = row['parent_genre_id'];
      final c = row['child_genre_id'];
      if (p is int && c is int) genreEdges.add(MapEntry(p, c));
    }

    final descriptorEdges = <MapEntry<int, int>>[];
    for (final row in dhRows) {
      final p = row['parent_descriptor_id'];
      final c = row['child_descriptor_id'];
      if (p is int && c is int) descriptorEdges.add(MapEntry(p, c));
    }

    RecordDetails build(Map<String, dynamic> r) {
      final id = r['record_id'] as int;
      Artist artistOf(MapEntry<int, Artist> e) => e.value;
      Genre genreOf(MapEntry<int, Genre> e) => e.value;
      Descriptor descriptorOf(MapEntry<int, Descriptor> e) => e.value;

      final recArtists = (artistsBy[id] ??= [])
        ..sort((a, b) => a.key.compareTo(b.key));
      final recGenres = (genresBy[id] ??= [])
        ..sort((a, b) => a.key.compareTo(b.key));
      final recDescriptors = (descriptorsBy[id] ??= [])
        ..sort((a, b) => a.key.compareTo(b.key));

      return RecordDetails(
        record: Record.fromJson(r),
        artists: recArtists.map(artistOf).toList(),
        genres: recGenres.map(genreOf).toList(),
        descriptors: recDescriptors.map(descriptorOf).toList(),
        streaming: List<StreamingService>.from(streamingBy[id] ?? const []),
      );
    }

    final rows = <RecordDetails>[];
    for (final r in records) {
      try {
        rows.add(build(r));
      } catch (e) {
        legFailures.add(
            'Record row skipped (record ${r['record_id']}): $e');
      }
    }
    return FetchResult(
      rows,
      legFailures,
      genreEdges: genreEdges,
      descriptorEdges: descriptorEdges,
    );
  }

  Future<void> updateFullRecord(RecordDetails details,
      {String originTab = 'search'}) async {
    final id = details.record.recordId!;

    await SupabaseService.fromWithContext(
            AppConstants.tableRecords, originTab)
        .update({
      'record_name': details.record.recordName,
      'record_type': details.record.recordType,
      'release_date': details.record.releaseDate,
      'release_date_mask': details.record.releaseDateMask,
      'comments': details.record.comments,
      'status': details.record.status,
    }).eq('record_id', id);

    await SupabaseService.fromWithContext(
            AppConstants.tableRecordArtists, originTab)
        .delete()
        .eq('record_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordGenres, originTab)
        .delete()
        .eq('record_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordDescriptors, originTab)
        .delete()
        .eq('record_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordStreaming, originTab)
        .delete()
        .eq('record_id', id);

    if (details.artists.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < details.artists.length; i++) {
        rows.add({
          'record_id': id,
          'artist_id': details.artists[i].artistId,
          'artist_order': i + 1,
        });
      }
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordArtists, originTab)
          .insert(rows);
    }

    if (details.genres.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < details.genres.length; i++) {
        rows.add({
          'record_id': id,
          'genre_id': details.genres[i].genreId,
          'genre_order': i + 1,
        });
      }
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordGenres, originTab)
          .insert(rows);
    }

    if (details.descriptors.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < details.descriptors.length; i++) {
        rows.add({
          'record_id': id,
          'descriptor_id': details.descriptors[i].descriptorId,
          'descriptor_order': i + 1,
        });
      }
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordDescriptors, originTab)
          .insert(rows);
    }

    if (details.streaming.isNotEmpty) {
      final rows = details.streaming
          .map((s) => {
                'record_id': id,
                'service_name': s.serviceName,
                'service_url': s.serviceUrl,
              })
          .toList();
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordStreaming, originTab)
          .insert(rows);
    }
  }

  Future<void> deleteRecord(int recordId,
      {String originTab = 'search'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordArtists, originTab)
        .delete()
        .eq('record_id', recordId);
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordGenres, originTab)
        .delete()
        .eq('record_id', recordId);
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordDescriptors, originTab)
        .delete()
        .eq('record_id', recordId);
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordStreaming, originTab)
        .delete()
        .eq('record_id', recordId);
    await SupabaseService.fromWithContext(AppConstants.tableRecords, originTab)
        .delete()
        .eq('record_id', recordId);
  }
}
