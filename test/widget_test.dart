import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicCollectionApp());
    expect(find.byType(MusicCollectionApp), findsOneWidget);
  });
}
