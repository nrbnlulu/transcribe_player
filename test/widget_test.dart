// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:transcribe_player/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TranscribePlayerApp());

    // Verify that the app title is displayed.
    expect(find.text('Transcribe Player'), findsOneWidget);
  });
}
