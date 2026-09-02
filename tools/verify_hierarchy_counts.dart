import 'dart:io';
import 'dart:convert';

const url = 'https://iqtrkvtwjapktzhnfiaz.supabase.co';
const key =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxdHJrdnR3amFwa3R6aG5maWF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTE0NjksImV4cCI6MjA5MTcyNzQ2OX0.sFi9VE4XRO6EYdVKx6Uc3YNKttuOJY2ji62w2daXFrI';
const pageSize = 1000;

Future<List<Map<String, dynamic>>> paginatedQuery(String table,
    {String select = '*', String? orderCol}) async {
  final all = <Map<String, dynamic>>[];
  var from = 0;
  while (true) {
    final qp = <String, String>{
      'select': select,
      if (orderCol != null) 'order': orderCol,
    };
    final uri = Uri.parse('$url/rest/v1/$table').replace(queryParameters: qp);
    final req = await HttpClient().getUrl(uri)
      ..headers.set('apikey', key)
      ..headers.set('Authorization', 'Bearer $key')
      ..headers.set('Range', '$from-${from + pageSize - 1}');
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    final rows = (decoded as List).cast<Map<String, dynamic>>();
    all.addAll(rows);
    if (rows.length < pageSize) break;
    from += pageSize;
  }
  return all;
}

Set<int> bfs(int start, Map<int, Set<int>> edges) {
  final visited = <int>{};
  final queue = [start];
  while (queue.isNotEmpty) {
    final cur = queue.removeLast();
    for (final child in edges[cur] ?? <int>{}) {
      if (visited.add(child)) queue.add(child);
    }
  }
  return visited;
}

void main() async {
  // --- GENRES ---
  final genreRows = await paginatedQuery('genres',
      select: 'genre_id,genre_name', orderCol: 'genre_name');
  final genreHierarchy = await paginatedQuery('genre_hierarchy',
      select: 'parent_genre_id,child_genre_id', orderCol: 'parent_genre_id');
  final genreRefs = await paginatedQuery('record_genres',
      select: 'record_id,genre_id', orderCol: 'record_id');

  print('Genres: ${genreRows.length} rows, ${genreHierarchy.length} hierarchy edges, ${genreRefs.length} record links');

  final genreNameById = <int, String>{};
  for (final r in genreRows) {
    genreNameById[r['genre_id'] as int] = r['genre_name'] as String;
  }

  final genreEdges = <int, Set<int>>{};
  for (final r in genreHierarchy) {
    final p = r['parent_genre_id'];
    final c = r['child_genre_id'];
    if (p is int && c is int) (genreEdges[p] ??= {}).add(c);
  }

  final genreDirectRefCounts = <int, int>{};
  for (final r in genreRefs) {
    final id = r['genre_id'] as int;
    genreDirectRefCounts[id] = (genreDirectRefCounts[id] ?? 0) + 1;
  }

  final genreBuf = StringBuffer();
  genreBuf.writeln('Genre ID,Name,Direct Children,Total Descendants,Total References,Subtree IDs');
  for (final id in genreNameById.keys.toList()
    ..sort((a, b) => (genreNameById[a]!).compareTo(genreNameById[b]!))) {
    final name = genreNameById[id]!.replaceAll('"', '""');
    final direct = genreEdges[id]?.length ?? 0;
    final all = bfs(id, genreEdges);
    final subtreeIds = all.toList()..sort();
    var totalRefs = genreDirectRefCounts[id] ?? 0;
    for (final gid in all) {
      totalRefs += genreDirectRefCounts[gid] ?? 0;
    }
    genreBuf.writeln(
        '$id,"$name",$direct,${all.length},$totalRefs,"{${subtreeIds.join(', ')}}"');
  }

  await File('tools/genre_children_results.csv')
      .writeAsString(genreBuf.toString());
  print('Saved tools/genre_children_results.csv (${genreRows.length} genres)');

  // --- DESCRIPTORS ---
  final descRows = await paginatedQuery('descriptors',
      select: 'descriptor_id,descriptor_name', orderCol: 'descriptor_name');
  final descHierarchy = await paginatedQuery('descriptor_hierarchy',
      select: 'parent_descriptor_id,child_descriptor_id', orderCol: 'parent_descriptor_id');
  final descRefs = await paginatedQuery('record_descriptors',
      select: 'record_id,descriptor_id', orderCol: 'record_id');

  print('Descriptors: ${descRows.length} rows, ${descHierarchy.length} hierarchy edges, ${descRefs.length} record links');

  final descNameById = <int, String>{};
  for (final r in descRows) {
    descNameById[r['descriptor_id'] as int] = r['descriptor_name'] as String;
  }

  final descEdges = <int, Set<int>>{};
  for (final r in descHierarchy) {
    final p = r['parent_descriptor_id'];
    final c = r['child_descriptor_id'];
    if (p is int && c is int) (descEdges[p] ??= {}).add(c);
  }

  final descDirectRefCounts = <int, int>{};
  for (final r in descRefs) {
    final id = r['descriptor_id'] as int;
    descDirectRefCounts[id] = (descDirectRefCounts[id] ?? 0) + 1;
  }

  final descBuf = StringBuffer();
  descBuf.writeln('Descriptor ID,Name,Direct Children,Total Descendants,Total References,Subtree IDs');
  for (final id in descNameById.keys.toList()
    ..sort((a, b) => (descNameById[a]!).compareTo(descNameById[b]!))) {
    final name = descNameById[id]!.replaceAll('"', '""');
    final direct = descEdges[id]?.length ?? 0;
    final all = bfs(id, descEdges);
    final subtreeIds = all.toList()..sort();
    var totalRefs = descDirectRefCounts[id] ?? 0;
    for (final did in all) {
      totalRefs += descDirectRefCounts[did] ?? 0;
    }
    descBuf.writeln(
        '$id,"$name",$direct,${all.length},$totalRefs,"{${subtreeIds.join(', ')}}"');
  }

  await File('tools/descriptor_children_results.csv')
      .writeAsString(descBuf.toString());
  print('Saved tools/descriptor_children_results.csv (${descRows.length} descriptors)');
}
