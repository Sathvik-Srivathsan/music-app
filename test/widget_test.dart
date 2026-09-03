import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/app.dart';
import 'package:music_collection/core/auth/auth_provider.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicCollectionApp());
    expect(find.byType(MusicCollectionApp), findsOneWidget);
  });

  test('AuthProvider is unauthenticated when Supabase is not initialized',
      () {
    final auth = AuthProvider();
    expect(auth.status, AuthStatus.unauthenticated);
    auth.dispose();
  });
}
