import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';

/// Verifies the length-tiered square tooltip behaviour of InfoTip and
/// its structured richMessage (bold status line first, then blank line,
/// then the multi-line body).
void main() {
  Future<Tooltip> pumpTip(
    WidgetTester tester, {
    String? status,
    required String body,
    bool isMandatory = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InfoTip(
          status: status,
          body: body,
          isMandatory: isMandatory,
        ),
      ),
    ));
    await tester.pump();
    return tester.widget<Tooltip>(find.byType(Tooltip));
  }

  testWidgets('short note uses the small square tier', (tester) async {
    final tip = await pumpTip(
      tester,
      status: 'Mandatory field',
      body: 'The release title.',
    );
    expect(tip.constraints!.maxWidth, 220);
  });

  testWidgets('medium note uses the medium tier', (tester) async {
    final tip = await pumpTip(
      tester,
      body: 'Short tags describing the sound/mood.\n' * 4,
    );
    expect(tip.constraints!.maxWidth, 300);
  });

  testWidgets('long note uses the wide tier', (tester) async {
    final long = List.filled(45, 'word').join(' ');
    expect(long.length, greaterThan(180));
    final tip = await pumpTip(tester, body: long);
    expect(tip.constraints!.maxWidth, 380);
  });

  testWidgets('mandatory tip leads with the status then a blank line',
      (tester) async {
    final tip = await pumpTip(
      tester,
      status: 'Mandatory - at least one artist',
      body: 'Line one.\nLine two.',
      isMandatory: true,
    );
    final spans = (tip.richMessage! as TextSpan).children!;
    expect(spans.length, 3);
    expect((spans[0] as TextSpan).text, 'Mandatory - at least one artist');
    expect((spans[1] as TextSpan).text, '\n\n');
    expect((spans[2] as TextSpan).text, 'Line one.\nLine two.');
  });

  testWidgets('non-mandatory tip shows only the body, no status line',
      (tester) async {
    final tip = await pumpTip(
      tester,
      status: null,
      body: 'Just the rules.\nNothing else.',
    );
    final spans = (tip.richMessage! as TextSpan).children!;
    expect(spans.length, 1);
    expect((spans[0] as TextSpan).text, 'Just the rules.\nNothing else.');
  });
}
