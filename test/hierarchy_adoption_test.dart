import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/shared/utils/hierarchy_adoption.dart';

/// Unit tests for the "adopt / leave" delete-prior edge math: when deleting
/// node A that has parents and children, adopting means each child GAINS all
/// of A's parents as extra parent edges (additive union), keeping every other
/// parent it already had. Only missing edges are added; self-loops are never
/// created, and the "as-is" path leaves every edge not touching A untouched.
///
/// The second group is a seeded randomized probe: it builds gnarly synthetic
/// graphs (nodes with 0..4 children, 0..3 parents, parent-child 2-cycles,
/// longer self-great-grandchild cycles, a self-loop in the bag, and duplicate
/// edge rows) and, for EVERY node in the graph, compares the helper's output
/// against an independent oracle that recomputes the expected edge set from
/// the raw edge bag with no calls to the code under test.
void main() {
  group('hand-written edge cases', () {
    test('adoption is additive (union) over children', () {
      // Tree:            D, E                D, E, F   D, E, G
      //                     \  \                \         \
      //                    A (deleted)          B         C
      //                   /  \   \
      //                 B    C    H
      //               / \    \
      //             F    G    (none extra)
      final added = adoptionEdgesToAdd(
        nodeId: 1,
        parents: {4, 5},
        children: {2, 3, 8},
        existingEdges: {
          (4, 1), // D -> A
          (5, 1), // E -> A
          (1, 2), // A -> B
          (1, 3), // A -> C
          (1, 8), // A -> H
          (6, 2), // F -> B
          (7, 3), // G -> C
        },
      );

      expect(added.toSet(), {
        (4, 2), // D -> B
        (5, 2), // E -> B
        (4, 3), // D -> C
        (5, 3), // E -> C
        (4, 8), // D -> H
        (5, 8), // E -> H
      });

      expect(
        childParentsAfterAdoption(
            child: 2, nodeParents: {4, 5}, childCurrentParents: {6}),
        {4, 5, 6},
      );
      expect(
        childParentsAfterAdoption(
            child: 3, nodeParents: {4, 5}, childCurrentParents: {7}),
        {4, 5, 7},
      );
      expect(
        childParentsAfterAdoption(
            child: 8, nodeParents: {4, 5}, childCurrentParents: {}),
        {4, 5},
      );
    });

    test('no edges added when every parent-child already exists', () {
      final added = adoptionEdgesToAdd(
        nodeId: 1,
        parents: {4, 5},
        children: {2},
        existingEdges: {(4, 1), (5, 1), (1, 2), (4, 2), (5, 2)},
      );
      expect(added, isEmpty);
    });

    test('self-loop in the bag is treated as a normal edge, never re-emitted',
        () {
      // Edge (0,0) exists in the bag. A = 1 has parent 0 and child 0 too.
      final added = adoptionEdgesToAdd(
        nodeId: 1,
        parents: {0, 2},
        children: {0, 3},
        existingEdges: {(0, 0), (0, 1), (2, 1), (1, 0), (1, 3)},
      );
      // Combinations of parents {0,2} x children {0,3}, skipping p==c:
      //  (0,0) p==c skip; (0,3) new add; (2,0) new add; (2,3) new add.
      // Self-loop (0,0) is never created regardless of bag contents.
      expect(added.toSet(), {(0, 3), (2, 0), (2, 3)});
    });

    test('deleting A that is its own child (cycle through A) skips self-loop',
        () {
      // A = 1 is both its own parent and its own child (1 -> 1), plus it is
      // its own great-grandchild through 1 -> 2 -> 1 and 1 -> 2 -> 3 -> 1.
      final added = adoptionEdgesToAdd(
        nodeId: 1,
        parents: {1, 4},
        children: {1, 5},
        existingEdges: {
          (1, 1), (4, 1), (1, 2), (2, 1), (1, 3), (3, 1), (1, 5),
        },
      );
      // parent 1 == child 1 -> skip. Only 4->1 (self-ish, already exists so
      // skipped) and 4->5 (new). parent 1 with child 5 -> (1,5) already exists.
      expect(added.toSet(), {(4, 5)});
    });

    test('parent-child 2-cycle is untouched for as-is and adopt', () {
      // X=10, Y=11 form a 2-cycle (10->11 and 11->10). A = 20 unrelated.
      final added = adoptionEdgesToAdd(
        nodeId: 20,
        parents: {10},
        children: {21},
        existingEdges: {(10, 11), (11, 10), (10, 20), (20, 21)},
      );
      // Adoption inserts 10->21. It must NOT touch the 2-cycle (10,11)/(11,10)
      // and must not create a duplicate of (10,20) or anything else.
      expect(added.toSet(), {(10, 21)});
      expect(added.where((e) => e == (10, 11) || e == (11, 10)), isEmpty);
    });
  });

  group('randomized adopt/leave graph probe (every node, all cases)', () {
    test('matches independent oracle across many gnarly trees', () {
      final rng = Random(20260830);
      var checked = 0;
      var withBoth = 0; // A nodes having children AND parents (dialog case)

      for (var n = 2; n <= 12; n++) {
        // 16 graphs per size -> 176 graphs total, ~up to 12 nodes each.
        for (var g = 0; g < 16; g++) {
          // Deterministically inject a couple of interesting cmponents per
          // graph so cycles/self-loops are guaranteed present across the sweep.
          final bag = <(int, int)>[]; // raw edge rows, duplicates allowed

          void addEdge(int p, int c) {
            // keep ids within [0, n)
            bag.add((p % n, c % n));
          }

          // 1) a parent-child 2-cycle
          addEdge(0, 1);
          addEdge(1, 0);
          // 2) a longer self-great-grandchild cycle: X -> A1 -> A2 -> X
          addEdge(2, 3);
          addEdge(3, 4);
          addEdge(4, 2);
          // 3) a self-loop present in the bag + a duplicate edge
          addEdge(5, 5);
          addEdge(6, 7);
          addEdge(6, 7); // duplicate row

          // 4) random density
          for (var i = 0; i < n * 2; i++) {
            addEdge(rng.nextInt(n), rng.nextInt(n));
          }

          // The as-is transformation mirrors deleteGenre/deleteDescriptor:
          // drop every edge that touches A, keep every other edge.
          for (var a = 0; a < n; a++) {
            final distinct = bag.toSet();
            final parentsX = <int, Set<int>>{};
            final childrenX = <int, Set<int>>{};
            final nodes = <int>{};
            for (final e in distinct) {
              nodes.add(e.$1);
              nodes.add(e.$2);
              parentsX.putIfAbsent(e.$2, () => {}).add(e.$1);
              childrenX.putIfAbsent(e.$1, () => {}).add(e.$2);
            }
            final parentsA = parentsX[a] ?? {};
            final childrenA = childrenX[a] ?? {};
            final existing = distinct;

            // Independent oracle for the added edges.
            final expected = <(int, int)>{};
            for (final c in childrenA) {
              for (final p in parentsA) {
                if (p != c && !existing.contains((p, c))) {
                  expected.add((p, c));
                }
              }
            }

            final added = adoptionEdgesToAdd(
              nodeId: a,
              parents: parentsA,
              children: childrenA,
              existingEdges: existing,
            );

            expect(added.toSet(), expected,
                reason: 'graph=$bag adopt A=$a');

            // Invariants
            final addedSet = added.toSet();
            expect(addedSet.length, added.length,
                reason: 'no duplicate add, graph=$bag A=$a');
            for (final e in added) {
              expect(e.$1 != e.$2, isTrue,
                  reason: 'no self-loop added, graph=$bag A=$a e=$e');
              expect(existing.contains(e), isFalse,
                  reason: 'added an edge already present, graph=$bag A=$a e=$e');
            }

            // childParentsAfterAdoption consistency, for every child.
            for (final c in childrenA) {
              final viaHelper = childParentsAfterAdoption(
                child: c,
                nodeParents: parentsA,
                childCurrentParents: parentsX[c] ?? {},
              );
              final viaOracle = (parentsX[c] ?? {})
                  .union(parentsA.where((p) => p != c).toSet());
              expect(viaHelper, viaOracle,
                  reason: 'child parents, graph=$bag A=$a c=$c');
            }

            // Count the realistic dialog case (children AND parents).
            if (childrenA.isNotEmpty && parentsA.isNotEmpty) {
              withBoth++;
            }
            checked++;
          }
        }
      }

      // The sweep is garbage unless it exercised the real dialog case a lot.
      expect(withBoth, greaterThan(50),
          reason: 'probe never produced enough A with children AND parents');
      expect(checked, greaterThan(500));
    });
  });
}
