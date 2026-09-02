import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';

void main() {
  const base = [
    ['A', 'x'],
    ['B', 'y'],
    ['C', 'z'],
    ['D', 'w'],
  ];

  group('ManageProvider.overlayRows', () {
    test('returns base unchanged when no modifications', () {
      final result = ManageProvider.overlayRows(base, {});
      expect(result, base);
    });

    test('keeps untouched rows and applies modifications in place', () {
      final result = ManageProvider.overlayRows(base, {
        1: ['B', 'fixed'],
      });
      expect(result, [
        ['A', 'x'],
        ['B', 'fixed'],
        ['C', 'z'],
        ['D', 'w'],
      ]);
    });

    test('preserves row order and empty-name (skipped) modifications', () {
      final result = ManageProvider.overlayRows(base, {
        0: ['', 'q'],
        2: ['C2', ''],
      });
      expect(result, [
        ['', 'q'],
        ['B', 'y'],
        ['C2', ''],
        ['D', 'w'],
      ]);
    });

    test('ignores out-of-range keys but keeps others', () {
      final result = ManageProvider.overlayRows(base, {
        5: ['E', 'nope'],
        3: ['D', 'over'],
      });
      expect(result, [
        ['A', 'x'],
        ['B', 'y'],
        ['C', 'z'],
        ['D', 'over'],
      ]);
    });
  });
}