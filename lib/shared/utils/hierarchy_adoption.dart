/// Pure helpers for the "adopt / leave" choice offered when deleting a
/// genre or descriptor that has children. No I/O - just edge-set math, so it
/// is trivially unit-testable.

/// Computes the (parentId, childId) hierarchy edges that must be ADDED when
/// [nodeId] is deleted and all of its children are adopted by all of its
/// parents (additive/union: each child keeps its existing parents and gains
/// every one of [nodeId]'s parents too). Missing edges only; self-loops and
/// already-existing edges are never returned.
List<(int, int)> adoptionEdgesToAdd({
  required int nodeId,
  required Set<int> parents,
  required Set<int> children,
  required Set<(int, int)> existingEdges,
}) {
  final toAdd = <(int, int)>[];
  for (final child in children) {
    for (final parent in parents) {
      if (parent == child) continue;
      final edge = (parent, child);
      if (!existingEdges.contains(edge)) toAdd.add(edge);
    }
  }
  return toAdd;
}

/// The full parent set a single [child] ends up with after adoption by
/// [nodeParents] - its existing parents UNION the deleted node's parents.
Set<int> childParentsAfterAdoption({
  required int child,
  required Set<int> nodeParents,
  required Set<int> childCurrentParents,
}) {
  final result = Set<int>.from(childCurrentParents);
  for (final p in nodeParents) {
    if (p != child) result.add(p);
  }
  return result;
}
