import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/features/manage/presentation/screens/manage_import_export_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Widget host(ManageProvider provider) {
    return ChangeNotifierProvider<ManageProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(body: ManageImportExportScreen()),
      ),
    );
  }

  testWidgets('Download Format of CSV button is hidden until Full Database is '
      'selected', (tester) async {
    final provider = ManageProvider();
    await tester.pumpWidget(host(provider));
    await tester.pumpAndSettle();

    // No entity selected -> the download-format button is not shown.
    expect(find.text('Choose CSV File'), findsOneWidget);
    expect(find.text('Download Format of CSV'), findsNothing);

    // Both Export and Import dropdowns contain a "Full Database" item;
    // pick the second one (the Import dropdown, to the right of Export).
    final importDropdown = find.byType(DropdownButton<ImportEntityType?>).last;
    await tester.tap(importDropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Full Database').last);
    await tester.pumpAndSettle();

    // Now that Full Database is selected for import, the button appears.
    expect(find.text('Download Format of CSV'), findsOneWidget);
    expect(find.byIcon(Icons.text_snippet_outlined), findsOneWidget);

    // It is enabled once an entity type is selected.
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Download Format of CSV'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });
}
