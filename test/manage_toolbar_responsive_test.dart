import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/features/manage/presentation/screens/manage_screen.dart';
import 'package:provider/provider.dart';

/// loadAll() hits the network; the toolbar layout under test does not
/// depend on loaded data, so it is stubbed out.
class _QuietManage extends ManageProvider {
  @override
  Future<void> loadAll() async {}
}

Widget _host(ManageProvider p) {
  return ChangeNotifierProvider<ManageProvider>.value(
    value: p,
    child: const MaterialApp(
      home: Scaffold(body: ManageScreen()),
    ),
  );
}

Future<void> _useSurface(WidgetTester tester, Size logical) async {
  // DPR first: physical pixels then equal logical pixels, so the pumped
  // surface is exactly `logical` (the ambient test DPR is 3.0, and scaling
  // by it would triple every requested size).
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = logical;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('narrow: search and Add stack on separate rows',
      (tester) async {
    await _useSurface(tester, const Size(500, 900));
    await tester.pumpWidget(_host(_QuietManage()));
    await tester.pumpAndSettle();
    final searchDy = tester.getCenter(find.byType(TextField)).dy;
    final addDy =
        tester.getCenter(find.widgetWithText(ElevatedButton, 'Add')).dy;
    expect(addDy, greaterThan(searchDy + 20));
    // Sub-tab bar collapses to a dropdown on narrow screens.
    expect(find.byType(DropdownButton<ManageSubTab>), findsOneWidget);
    expect(find.byType(SegmentedButton<ManageSubTab>), findsNothing);
  });

  testWidgets('wide: search and Add share one row', (tester) async {
    await _useSurface(tester, const Size(1400, 900));
    await tester.pumpWidget(_host(_QuietManage()));
    await tester.pumpAndSettle();
    final searchDy = tester.getCenter(find.byType(TextField)).dy;
    final addDy =
        tester.getCenter(find.widgetWithText(ElevatedButton, 'Add')).dy;
    expect((addDy - searchDy).abs(), lessThan(20));
    // Sub-tab bar stays a 4-segment control on wide screens.
    expect(find.byType(SegmentedButton<ManageSubTab>), findsOneWidget);
    expect(find.byType(DropdownButton<ManageSubTab>), findsNothing);
  });
}
