import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/app.dart';
import 'package:music_collection/core/auth/login_screen.dart';

// Regression tests for the Android system-back-button handling.
//
// go_router 17.x crashes ("Null check operator used on a null value") on
// every system back press inside the Offstage-based tab shell because the
// ShellRoute builder ignores `child`, so go_router's shell navigator never
// mounts. The app registers a root-level `WidgetsBindingObserver` (before the
// router mounts) that intercepts the back press first: it closes any open
// root-navigator modal, and otherwise exits the app.
void main() {
  setUp(() {
    // Make the platform channel used by SystemNavigator.pop resolve so a
    // back-press at root (which exits the app) completes in the test env.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  testWidgets('system back with a dialog open closes the dialog, no crash',
      (tester) async {
    await tester.pumpWidget(const MusicCollectionApp());
    await tester.pumpAndSettle();

    // Context inside MaterialApp (under MaterialLocalizations) so showDialog
    // works; it places the dialog on the ROOT navigator (default).
    final ctx = tester.element(find.byType(LoginScreen));
    showDialog<void>(
      context: ctx,
      builder: (_) => const AlertDialog(
        title: Text('ANDROID_BACK_DIALOG'),
        content: Text('content'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ANDROID_BACK_DIALOG'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'system back must not hit go_router null-check crash');
    expect(find.text('ANDROID_BACK_DIALOG'), findsNothing,
        reason: 'system back should close the open dialog');
  });

  testWidgets('system back with no dialog/open modal does not crash',
      (tester) async {
    await tester.pumpWidget(const MusicCollectionApp());
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'system back at root must never throw');
  });
}
