import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/shared/widgets/chip_input_field.dart';

/// Series 2b — widget-level integration tests for ChipInputField.
/// Reproduces the exact user flows: paste + Enter/Confirm, recommendation
/// clicks, and chip removal driven by deleting committed text.
void main() {
  const dbItems = [
    'Merzbow',
    'Denzel Curry',
    'Abstract Hip Hop',
    'Conscious Hip Hop',
    'Jazz Rap',
    'Experimental Hip Hop',
  ];

  late List<List<String>> itemsLog;
  late List<String> createdLog;

  Future<void> pumpField(WidgetTester tester) async {
    itemsLog = [];
    createdLog = [];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChipInputField<String>(
            labelText: 'Genres',
            allItems: dbItems,
            itemToString: (s) => s,
            similarityFn: (q, s) => CsvUtils.calculateSimilarity(q, s),
            onCreateNew: (name) async {
              createdLog.add(name);
              return name;
            },
            onItemsChanged: (items) => itemsLog.add(List.from(items)),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  TextEditingController controllerOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  void appendText(WidgetTester tester, String addition) {
    final controller = controllerOf(tester);
    final base = controller.text;
    controller.value = TextEditingValue(
      text: '$base$addition',
      selection:
          TextSelection.collapsed(offset: base.length + addition.length),
    );
  }

  Future<void> commitViaButton(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
  }

  group('Series 2b - paste + commit', () {
    testWidgets('paste + Confirm commits every segment, zero popups',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField),
          'Abstract Hip Hop, Conscious Hip Hop, Jazz Rap');
      await tester.pump();

      await commitViaButton(tester);

      expect(itemsLog.last,
          ['Abstract Hip Hop', 'Conscious Hip Hop', 'Jazz Rap']);
      expect(createdLog, isEmpty);
      expect(controllerOf(tester).text,
          'Abstract Hip Hop, Conscious Hip Hop, Jazz Rap, ');
    });

    testWidgets('Enter key commits active text', (tester) async {
      await pumpField(tester);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Merzbow');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Merzbow']);
      expect(createdLog, isEmpty);
      expect(controllerOf(tester).text, 'Merzbow, ');
    });

    testWidgets('duplicate segment commits once, no popup', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField),
          'Jazz Rap, Conscious Hip Hop, Jazz Rap');
      await tester.pump();

      await commitViaButton(tester);

      expect(createdLog, isEmpty);
      expect(itemsLog.last, ['Jazz Rap', 'Conscious Hip Hop']);
    });
  });

  group('Series 2b - recommendation click', () {
    testWidgets('tapping a dropdown recommendation commits the chip',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'merz');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Merzbow'));
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Merzbow']);
      expect(createdLog, isEmpty);
      expect(controllerOf(tester).text, 'Merzbow, ');
    });

    testWidgets('dropdown stays open after a pick; consecutive picks commit',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'merz');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Merzbow'));
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Merzbow']);
      // Regression: the dropdown must NOT die after the first pick.
      expect(find.text('Denzel Curry'), findsOneWidget);

      await tester.tap(find.text('Denzel Curry'));
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Merzbow', 'Denzel Curry']);
      expect(createdLog, isEmpty);
      expect(controllerOf(tester).text, 'Merzbow, Denzel Curry, ');
    });
  });

  group('Series 2b - unmatched -> create flow', () {
    testWidgets('fuzzy-only partial opens create exactly once',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'merzbo');
      await tester.pump();

      await commitViaButton(tester);

      expect(createdLog, ['merzbo']);
      expect(itemsLog.last, ['merzbo']);
    });

    testWidgets('mixed batch: matches commit, misses go to create',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(
          find.byType(TextField), 'Merzbow, jazz rap, merzbo');
      await tester.pump();

      await commitViaButton(tester);

      expect(createdLog, ['merzbo']);
      expect(itemsLog.last, ['Merzbow', 'Jazz Rap', 'merzbo']);
    });
  });

  group('Series 2b - deleting committed text syncs chips', () {
    testWidgets('deleting a trailing segment removes only that chip',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'Merzbow');
      await tester.pump();
      await commitViaButton(tester);

      appendText(tester, 'Denzel Curry');
      await tester.pump();
      await commitViaButton(tester);
      expect(itemsLog.last, ['Merzbow', 'Denzel Curry']);

      // Simulate deleting ", Denzel Curry" from the box.
      await tester.enterText(find.byType(TextField), 'Merzbow');
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Merzbow']);
      expect(controllerOf(tester).text, 'Merzbow, ');
    });

    testWidgets('deleting into a name turns remnant white and drops chip',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'Merzbow');
      await tester.pump();
      await commitViaButton(tester);

      appendText(tester, 'Denzel Curry');
      await tester.pump();
      await commitViaButton(tester);

      // Backspace deep enough to corrupt the last name.
      final controller = controllerOf(tester);
      const truncated = 'Merzbow, Denze';
      controller.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Merzbow']);
      expect(controllerOf(tester).text, 'Merzbow, ');
    });

    testWidgets('clearing the whole box removes all chips', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'Merzbow, Jazz Rap');
      await tester.pump();
      await commitViaButton(tester);
      expect(itemsLog.last, ['Merzbow', 'Jazz Rap']);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(itemsLog.last, isEmpty);
      expect(controllerOf(tester).text, '');
    });
  });

  group('Series 2b - uniform chip sizing', () {
    testWidgets('all chips share the longest label width', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'Merzbow');
      await tester.pump();
      await commitViaButton(tester);

      appendText(tester, 'Denzel Curry');
      await tester.pump();
      await commitViaButton(tester);
      await tester.pumpAndSettle();

      final chips = find.byType(Chip);
      expect(chips, findsNWidgets(2));

      final sizeA = tester.getSize(chips.at(0));
      final sizeB = tester.getSize(chips.at(1));
      expect(sizeA.width, closeTo(sizeB.width, 0.5));
      // Both must be as wide as the LONGEST label demands.
      expect(sizeA.width, greaterThan(120));
    });

    testWidgets('chip width shrinks after the longest chip is removed',
        (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'Denzel Curry');
      await tester.pump();
      await commitViaButton(tester);

      appendText(tester, 'Merzbow');
      await tester.pump();
      await commitViaButton(tester);
      await tester.pumpAndSettle();

      final wideBefore = tester.getSize(find.byType(Chip).at(0)).width;

      // Delete "Denzel Curry" by clearing its text from the box.
      await tester.enterText(find.byType(TextField), 'Merzbow');
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Merzbow']);
      final wideAfter = tester.getSize(find.byType(Chip)).width;
      expect(wideAfter, lessThan(wideBefore));
    });
  });

  group('sortFn + usedIds params', () {
    testWidgets('sortFn orders dropdown items when query empty', (tester) async {
      itemsLog = [];
      createdLog = [];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChipInputField<String>(
            labelText: 'Test',
            allItems: const ['Zebra', 'Apple', 'Mango'],
            itemToString: (s) => s,
            similarityFn: (_, __) => 0.0,
            onCreateNew: (n) async => n,
            onItemsChanged: (items) => itemsLog.add(items),
            sortFn: (a, b) => a.compareTo(b),
          ),
        ),
      ));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final labels = ['Apple', 'Mango', 'Zebra'];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
      // Verify order by checking the Material/Column children
      final texts = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(Material).last,
          matching: find.byType(Text),
        ),
      ).map((t) => t.data).toList();
      expect(texts, containsAllInOrder(['Apple', 'Mango', 'Zebra']));
    });

    testWidgets('usedIds filters dropdown to matching items', (tester) async {
      itemsLog = [];
      createdLog = [];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChipInputField<String>(
            labelText: 'Test',
            allItems: const ['Apple', 'Banana', 'Cherry'],
            itemToString: (s) => s,
            similarityFn: (_, __) => 0.0,
            onCreateNew: (n) async => n,
            onItemsChanged: (items) => itemsLog.add(items),
            usedIds: {0, 2},
            getId: (s) => s == 'Apple' ? 0 : s == 'Banana' ? 1 : 2,
          ),
        ),
      ));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });
  });

  group('Series 2b - arrow-key preview', () {
    const hipGenres = ['Abstract Hip Hop', 'Conscious Hip Hop', 'Experimental Hip Hop'];

    Future<void> focusAndType(WidgetTester tester, String text) async {
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }

    testWidgets('ArrowDown previews a recommendation without committing',
        (tester) async {
      await pumpField(tester);
      await focusAndType(tester, 'hip');
      await tester.pumpAndSettle();

      expect(itemsLog, isEmpty);
      expect(createdLog, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // The active text is now a preview of a real recommendation, NOT
      // committed yet.
      final text = controllerOf(tester).text;
      expect(hipGenres, contains(text));
      expect(itemsLog, isEmpty,
          reason: 'arrow keys must only preview, never auto-commit');
      expect(createdLog, isEmpty);
    });

    testWidgets('Enter after ArrowDown commits the previewed recommendation',
        (tester) async {
      await pumpField(tester);
      await focusAndType(tester, 'hip');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final preview = controllerOf(tester).text;
      expect(hipGenres, contains(preview));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(itemsLog.last, [preview]);
      expect(createdLog, isEmpty);
      expect(controllerOf(tester).text, '$preview, ');
    });

    testWidgets('arrow keys cycle through previews and wrap', (tester) async {
      await pumpField(tester);
      await focusAndType(tester, 'hip');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final first = controllerOf(tester).text;
      expect(hipGenres, contains(first));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final second = controllerOf(tester).text;
      expect(hipGenres, contains(second));
      expect(second, isNot(first));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(controllerOf(tester).text, first);
    });

    testWidgets('dropdown keeps all options while arrow-navigating', (tester) async {
      await pumpField(tester);
      await focusAndType(tester, 'hip');
      await tester.pumpAndSettle();

      // Dropdown list length == full match set before any arrow press.
      int dropdownItemCount() {
        final lv = tester.widget<ListView>(find.byType(ListView));
        return lv.childrenDelegate.estimatedChildCount ?? 0;
      }

      final before = dropdownItemCount();
      expect(before, 3);

      // Arrow around the whole set; the visible list must NOT collapse to
      // the single previewed name (that was the "options vanish" bug).
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(dropdownItemCount(), 3,
            reason: 'dropdown must stay the same size while previewing');
      }
      expect(itemsLog, isEmpty);
      expect(createdLog, isEmpty);
    });

    testWidgets('typing after a preview clears the highlight and edits text',
        (tester) async {
      await pumpField(tester);
      await focusAndType(tester, 'hip');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // User keeps typing: active text becomes the new edit, no commit.
      await tester.enterText(find.byType(TextField), 'merz');
      await tester.pumpAndSettle();

      expect(controllerOf(tester).text, 'merz');
      expect(itemsLog, isEmpty);
      expect(createdLog, isEmpty);
    });
  });

  group('Series 2b - comma in entity name (artists)', () {
    const commaItems = ['Earth, Wind and Fire', 'Denzel Curry', 'Merzbow'];

    Future<void> pumpCommaField(WidgetTester tester) async {
      itemsLog = [];
      createdLog = [];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChipInputField<String>(
            labelText: 'Artists',
            allItems: commaItems,
            itemToString: (s) => s,
            similarityFn: (q, s) => CsvUtils.calculateSimilarity(q, s),
            onCreateNew: (name) async {
              createdLog.add(name);
              return name;
            },
            onItemsChanged: (items) => itemsLog.add(List.from(items)),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets(
        'ArrowDown + Enter commits the whole comma-named artist (Part A)',
        (tester) async {
      await pumpCommaField(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'earth');
      await tester.pumpAndSettle();

      // The suggestion carrying the comma is the single match expected.
      expect(find.text('Earth, Wind and Fire'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // The comma inside the name must NOT fragment it into two artists.
      expect(itemsLog.last, ['Earth, Wind and Fire']);
      expect(createdLog, isEmpty,
          reason: 'a comma-named suggestion must not open a create popup');
      expect(controllerOf(tester).text, 'Earth, Wind and Fire, ');
    });

    testWidgets('typed exact name with comma commits as one artist (Part B)',
        (tester) async {
      await pumpCommaField(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(
          find.byType(TextField), 'Earth, Wind and Fire');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(itemsLog.last, ['Earth, Wind and Fire']);
      expect(createdLog, isEmpty);
      expect(controllerOf(tester).text, 'Earth, Wind and Fire, ');
    });

    testWidgets('genuine multi-artist paste still splits into separate chips',
        (tester) async {
      await pumpCommaField(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Denzel Curry, Merzbow');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Neither whole string matches a single existing entity, so it must
      // split back into the two distinct artists.
      expect(itemsLog.last, ['Denzel Curry', 'Merzbow']);
      expect(createdLog, isEmpty);
    });
  });
}
