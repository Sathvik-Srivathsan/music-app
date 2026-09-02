/// Transitive parent->child closures over the taxonomy edge tables
/// (genre_hierarchy / descriptor_hierarchy). Selecting "Rock" must
/// surface every descendant subgenre, so the repository ships the raw
/// edges and this module expands selections once per fetch.
library;

/// edges: child -> parents is how the table reads
/// (parent_genre_id, child_genre_id); we index parent -> children.
Map<int, Set<int>> buildChildrenIndex(Iterable<MapEntry<int, int>> edges) {
  final idx = <int, Set<int>>{};
  for (final e in edges) {
    (idx[e.key] ??= {}).add(e.value);
  }
  return idx;
}

/// Closure of [root] including itself: root plus every descendant
/// reachable through the parent->children index. Cycle-safe.
Set<int> closureOf(int root, Map<int, Set<int>> childrenIndex) {
  final out = <int>{root};
  final stack = <int>[root];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    for (final child in childrenIndex[node] ?? const <int>{}) {
      if (out.add(child)) stack.add(child);
    }
  }
  return out;
}

/// Union of closures for every selected id - used by ANY-mode matching.
Set<int> unionClosures(
    Iterable<int> roots, Map<int, Set<int>> childrenIndex) {
  final out = <int>{};
  for (final r in roots) {
    out.addAll(closureOf(r, childrenIndex));
  }
  return out;
}

/// id -> FULL transitive closure (self included) for every node that
/// appears as a parent. This is the lookup shape the search engine
/// expects - one hash hop resolves an entire subtree.
Map<int, Set<int>> fullClosures(Iterable<MapEntry<int, int>> edges) {
  final idx = buildChildrenIndex(edges);
  return {
    for (final parent in idx.keys) parent: closureOf(parent, idx),
  };
}
