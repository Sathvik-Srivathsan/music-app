import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/network/supabase_client.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/record.dart';
import 'package:music_collection/shared/utils/hierarchy_adoption.dart';

class EntityWithRefCount<T> {
  final T entity;
  final int refCount;
  final int childrenCount;
  final int totalRefCount;

  const EntityWithRefCount({
    required this.entity,
    required this.refCount,
    this.childrenCount = 0,
    this.totalRefCount = 0,
  });
}

class ManageRepository {
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

  Future<List<EntityWithRefCount<Artist>>> fetchArtistsWithRefCount() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableArtists, orderColumn: 'artist_name');

    return (data as List).map((row) {
      final artist = Artist.fromJson(row);
      return EntityWithRefCount(
        entity: artist,
        refCount: row['ref_count'] as int? ?? 0,
      );
    }).toList();
  }

  Future<Artist> createArtist(String name,
      {String originTab = 'manage'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableArtists, originTab)
        .insert({'artist_name': name})
        .select()
        .single();
    return Artist.fromJson(data);
  }

  Future<Artist> renameArtist(int id, String newName,
      {String originTab = 'manage'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableArtists, originTab)
        .update({'artist_name': newName})
        .eq('artist_id', id)
        .select()
        .single();
    return Artist.fromJson(data);
  }

  Future<void> deleteArtist(int id, {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordArtists, originTab)
        .delete()
        .eq('artist_id', id);
    await SupabaseService.fromWithContext(AppConstants.tableArtists, originTab)
        .delete()
        .eq('artist_id', id);
  }

  // --- Genres ---

  Future<List<EntityWithRefCount<Genre>>> fetchGenresWithRefCount() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableGenres, orderColumn: 'genre_name');

    return (data as List).map((row) {
      final genre = Genre.fromJson(row);
      return EntityWithRefCount(
        entity: genre,
        refCount: row['ref_count'] as int? ?? 0,
        childrenCount: row['children_count'] as int? ?? 0,
        totalRefCount: row['total_ref_count'] as int? ?? 0,
      );
    }).toList();
  }

  Future<Genre> createGenre(String name,
      {String originTab = 'manage'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableGenres, originTab)
        .insert({'genre_name': name})
        .select()
        .single();
    return Genre.fromJson(data);
  }

  Future<Genre> renameGenre(int id, String newName,
      {String originTab = 'manage'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableGenres, originTab)
        .update({'genre_name': newName})
        .eq('genre_id', id)
        .select()
        .single();
    return Genre.fromJson(data);
  }

  Future<void> deleteGenre(int id, {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordGenres, originTab)
        .delete()
        .eq('genre_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableGenreHierarchy, originTab)
        .delete()
        .eq('child_genre_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableGenreHierarchy, originTab)
        .delete()
        .eq('parent_genre_id', id);
    await SupabaseService.fromWithContext(AppConstants.tableGenres, originTab)
        .delete()
        .eq('genre_id', id);
  }

  // --- Descriptors ---

  Future<List<EntityWithRefCount<Descriptor>>> fetchDescriptorsWithRefCount() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableDescriptors, orderColumn: 'descriptor_name');

    return (data as List).map((row) {
      final descriptor = Descriptor.fromJson(row);
      return EntityWithRefCount(
        entity: descriptor,
        refCount: row['ref_count'] as int? ?? 0,
        childrenCount: row['children_count'] as int? ?? 0,
        totalRefCount: row['total_ref_count'] as int? ?? 0,
      );
    }).toList();
  }

  Future<Descriptor> createDescriptor(String name,
      {String originTab = 'manage'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableDescriptors, originTab)
        .insert({'descriptor_name': name})
        .select()
        .single();
    return Descriptor.fromJson(data);
  }

  Future<Descriptor> renameDescriptor(int id, String newName,
      {String originTab = 'manage'}) async {
    final data = await SupabaseService.fromWithContext(
            AppConstants.tableDescriptors, originTab)
        .update({'descriptor_name': newName})
        .eq('descriptor_id', id)
        .select()
        .single();
    return Descriptor.fromJson(data);
  }

  Future<void> deleteDescriptor(int id,
      {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableRecordDescriptors, originTab)
        .delete()
        .eq('descriptor_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableDescriptorHierarchy, originTab)
        .delete()
        .eq('child_descriptor_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableDescriptorHierarchy, originTab)
        .delete()
        .eq('parent_descriptor_id', id);
    await SupabaseService.fromWithContext(
            AppConstants.tableDescriptors, originTab)
        .delete()
        .eq('descriptor_id', id);
  }

  // --- Hierarchy Edges ---

  Future<List<(int parentId, int childId)>> fetchGenreHierarchyEdges() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableGenreHierarchy, orderColumn: 'parent_genre_id');
    return (data as List).map((row) {
      return (row['parent_genre_id'] as int, row['child_genre_id'] as int);
    }).toList();
  }

  Future<List<(int parentId, int childId)>> fetchDescriptorHierarchyEdges() async {
    final data = await _fetchAllPaginated(
        table: AppConstants.tableDescriptorHierarchy, orderColumn: 'parent_descriptor_id');
    return (data as List).map((row) {
      return (row['parent_descriptor_id'] as int, row['child_descriptor_id'] as int);
    }).toList();
  }

  // --- Batch Insert (Import) ---

  static const int _batchSize = 500;

  Future<int> batchInsertArtists(List<String> names,
      {String originTab = 'manage'}) async {
    if (names.isEmpty) return 0;
    for (var i = 0; i < names.length; i += _batchSize) {
      final chunk = names.sublist(i, (i + _batchSize).clamp(0, names.length));
      await SupabaseService.fromWithContext(AppConstants.tableArtists, originTab)
          .insert(chunk.map((n) => {'artist_name': n}).toList());
    }
    return names.length;
  }

  Future<Map<String, int>> batchInsertGenres(List<String> names,
      {String originTab = 'manage'}) async {
    if (names.isEmpty) return {};
    final nameToId = <String, int>{};
    for (var i = 0; i < names.length; i += _batchSize) {
      final chunk = names.sublist(i, (i + _batchSize).clamp(0, names.length));
      final data = await SupabaseService.fromWithContext(
              AppConstants.tableGenres, originTab)
          .insert(chunk.map((n) => {'genre_name': n}).toList())
          .select();
      for (final row in data) {
        nameToId[row['genre_name'] as String] = row['genre_id'] as int;
      }
    }
    return nameToId;
  }

  Future<void> batchInsertGenreHierarchy(
      List<(int parentId, int childId)> edges,
      {String originTab = 'manage'}) async {
    if (edges.isEmpty) return;
    for (var i = 0; i < edges.length; i += _batchSize) {
      final chunk = edges.sublist(i, (i + _batchSize).clamp(0, edges.length));
      await SupabaseService.fromWithContext(
              AppConstants.tableGenreHierarchy, originTab)
          .insert(
        chunk
            .map((e) => {
                  'parent_genre_id': e.$1,
                  'child_genre_id': e.$2,
                })
            .toList(),
      );
    }
  }

  Future<Map<String, int>> batchInsertDescriptors(List<String> names,
      {String originTab = 'manage'}) async {
    if (names.isEmpty) return {};
    final nameToId = <String, int>{};
    for (var i = 0; i < names.length; i += _batchSize) {
      final chunk = names.sublist(i, (i + _batchSize).clamp(0, names.length));
      final data = await SupabaseService.fromWithContext(
              AppConstants.tableDescriptors, originTab)
          .insert(chunk.map((n) => {'descriptor_name': n}).toList())
          .select();
      for (final row in data) {
        nameToId[row['descriptor_name'] as String] =
            row['descriptor_id'] as int;
      }
    }
    return nameToId;
  }

  Future<void> batchInsertDescriptorHierarchy(
      List<(int parentId, int childId)> edges,
      {String originTab = 'manage'}) async {
    if (edges.isEmpty) return;
    for (var i = 0; i < edges.length; i += _batchSize) {
      final chunk = edges.sublist(i, (i + _batchSize).clamp(0, edges.length));
      await SupabaseService.fromWithContext(
              AppConstants.tableDescriptorHierarchy, originTab)
          .insert(
        chunk
            .map((e) => {
                  'parent_descriptor_id': e.$1,
                  'child_descriptor_id': e.$2,
                })
            .toList(),
      );
    }
  }

  // --- Hierarchy Edge Management ---

  Future<Set<int>> fetchGenreParentIds(int childId) async {
    final data = await SupabaseService.from(AppConstants.tableGenreHierarchy)
        .select('parent_genre_id')
        .eq('child_genre_id', childId);
    return (data as List).map((r) => r['parent_genre_id'] as int).toSet();
  }

  Future<Set<int>> fetchDescriptorParentIds(int childId) async {
    final data = await SupabaseService.from(AppConstants.tableDescriptorHierarchy)
        .select('parent_descriptor_id')
        .eq('child_descriptor_id', childId);
    return (data as List).map((r) => r['parent_descriptor_id'] as int).toSet();
  }

  Future<Set<int>> fetchGenreChildIds(int parentId) async {
    final data =
        await SupabaseService.from(AppConstants.tableGenreHierarchy)
            .select('child_genre_id')
            .eq('parent_genre_id', parentId);
    return (data as List)
        .map((r) => r['child_genre_id'] as int)
        .toSet();
  }

  Future<Set<int>> fetchDescriptorChildIds(int parentId) async {
    final data =
        await SupabaseService.from(AppConstants.tableDescriptorHierarchy)
            .select('child_descriptor_id')
            .eq('parent_descriptor_id', parentId);
    return (data as List)
        .map((r) => r['child_descriptor_id'] as int)
        .toSet();
  }

  /// Additive adoption: every child of [nodeId] gains all of [nodeId]'s
  /// parents as ADDITIONAL direct parents (missing edges only, existing
  /// parents of each child are preserved). Self-loops are never created.
  Future<void> adoptGenreChildren(int nodeId,
      {String originTab = 'manage'}) async {
    final parents = await fetchGenreParentIds(nodeId);
    final children = await fetchGenreChildIds(nodeId);
    final existing = (await fetchGenreHierarchyEdges())
        .map((e) => (e.$1, e.$2))
        .toSet();
    final toAdd = adoptionEdgesToAdd(
      nodeId: nodeId,
      parents: parents,
      children: children,
      existingEdges: existing,
    );
    for (final edge in toAdd) {
      await addGenreHierarchyEdge(edge.$1, edge.$2, originTab: originTab);
    }
  }

  Future<void> adoptDescriptorChildren(int nodeId,
      {String originTab = 'manage'}) async {
    final parents = await fetchDescriptorParentIds(nodeId);
    final children = await fetchDescriptorChildIds(nodeId);
    final existing = (await fetchDescriptorHierarchyEdges())
        .map((e) => (e.$1, e.$2))
        .toSet();
    final toAdd = adoptionEdgesToAdd(
      nodeId: nodeId,
      parents: parents,
      children: children,
      existingEdges: existing,
    );
    for (final edge in toAdd) {
      await addDescriptorHierarchyEdge(edge.$1, edge.$2, originTab: originTab);
    }
  }

  Future<void> addGenreHierarchyEdge(int parentId, int childId,
      {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableGenreHierarchy, originTab)
        .upsert({
      'parent_genre_id': parentId,
      'child_genre_id': childId,
    });
  }

  Future<void> removeGenreHierarchyEdge(int parentId, int childId,
      {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableGenreHierarchy, originTab)
        .delete()
        .eq('parent_genre_id', parentId)
        .eq('child_genre_id', childId);
  }

  Future<void> addDescriptorHierarchyEdge(int parentId, int childId,
      {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableDescriptorHierarchy, originTab)
        .upsert({
      'parent_descriptor_id': parentId,
      'child_descriptor_id': childId,
    });
  }

  Future<void> removeDescriptorHierarchyEdge(int parentId, int childId,
      {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableDescriptorHierarchy, originTab)
        .delete()
        .eq('parent_descriptor_id', parentId)
        .eq('child_descriptor_id', childId);
  }

  Future<void> setGenreParents(int childId, Set<int> parentIds,
      {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableGenreHierarchy, originTab)
        .delete()
        .eq('child_genre_id', childId);
    if (parentIds.isEmpty) return;
    for (final pid in parentIds) {
      await SupabaseService.fromWithContext(
              AppConstants.tableGenreHierarchy, originTab)
          .insert({
        'parent_genre_id': pid,
        'child_genre_id': childId,
      });
    }
  }

  Future<void> setDescriptorParents(int childId, Set<int> parentIds,
      {String originTab = 'manage'}) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableDescriptorHierarchy, originTab)
        .delete()
        .eq('child_descriptor_id', childId);
    if (parentIds.isEmpty) return;
    for (final pid in parentIds) {
      await SupabaseService.fromWithContext(
              AppConstants.tableDescriptorHierarchy, originTab)
          .insert({
        'parent_descriptor_id': pid,
        'child_descriptor_id': childId,
      });
    }
  }

  // --- Full Database Import: Record Batch Inserts ---

  Future<List<String>> fetchRecordNames() async {
    try {
      final data =
          await SupabaseService.from(AppConstants.tableRecords).select('record_name');
      return data.map((r) => r['record_name'] as String).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<Map<String, int>> batchInsertRecords(List<Record> records,
      {String originTab = 'manage'}) async {
    if (records.isEmpty) return {};
    final nameToId = <String, int>{};
    for (var i = 0; i < records.length; i += _batchSize) {
      final chunk = records.sublist(i, (i + _batchSize).clamp(0, records.length));
      final data = await SupabaseService.fromWithContext(
              AppConstants.tableRecords, originTab)
          .insert(chunk
              .map((r) => {
                    'record_name': r.recordName,
                    'record_type': r.recordType,
                    'release_date': r.releaseDate,
                    'date_added': r.dateAdded,
                    'comments': r.comments,
                    'status': r.status,
                  })
              .toList())
          .select();
      for (final row in data) {
        nameToId[row['record_name'] as String] = row['record_id'] as int;
      }
    }
    return nameToId;
  }

  Future<void> batchInsertRecordArtists(
      List<(int recordId, int artistId, int order)> rows,
      {String originTab = 'manage'}) async {
    if (rows.isEmpty) return;
    for (var i = 0; i < rows.length; i += _batchSize) {
      final chunk = rows.sublist(i, (i + _batchSize).clamp(0, rows.length));
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordArtists, originTab)
          .insert(
        chunk
            .map((e) => {
                  'record_id': e.$1,
                  'artist_id': e.$2,
                  'artist_order': e.$3,
                })
            .toList(),
      );
    }
  }

  Future<void> batchInsertRecordGenres(
      List<(int recordId, int genreId, int order)> rows,
      {String originTab = 'manage'}) async {
    if (rows.isEmpty) return;
    for (var i = 0; i < rows.length; i += _batchSize) {
      final chunk = rows.sublist(i, (i + _batchSize).clamp(0, rows.length));
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordGenres, originTab)
          .insert(
        chunk
            .map((e) => {
                  'record_id': e.$1,
                  'genre_id': e.$2,
                  'genre_order': e.$3,
                })
            .toList(),
      );
    }
  }

  Future<void> batchInsertRecordDescriptors(
      List<(int recordId, int descriptorId, int order)> rows,
      {String originTab = 'manage'}) async {
    if (rows.isEmpty) return;
    for (var i = 0; i < rows.length; i += _batchSize) {
      final chunk = rows.sublist(i, (i + _batchSize).clamp(0, rows.length));
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordDescriptors, originTab)
          .insert(
        chunk
            .map((e) => {
                  'record_id': e.$1,
                  'descriptor_id': e.$2,
                  'descriptor_order': e.$3,
                })
            .toList(),
      );
    }
  }

  Future<void> batchInsertRecordStreaming(
      List<(int recordId, String serviceName, String serviceUrl)> rows,
      {String originTab = 'manage'}) async {
    if (rows.isEmpty) return;
    for (var i = 0; i < rows.length; i += _batchSize) {
      final chunk = rows.sublist(i, (i + _batchSize).clamp(0, rows.length));
      await SupabaseService.fromWithContext(
              AppConstants.tableRecordStreaming, originTab)
          .insert(
        chunk
            .map((e) => {
                  'record_id': e.$1,
                  'service_name': e.$2,
                  'service_url': e.$3,
                })
            .toList(),
      );
    }
  }

  // --- Audit Log ---

  Future<void> logAction({
    required String action,
    required String tableName,
    Map<String, dynamic>? details,
  }) async {
    await SupabaseService.fromWithContext(
            AppConstants.tableAuditLog, 'manage')
        .insert({
      'action': action,
      'table_name': tableName,
      'details': details,
    });
  }
}
