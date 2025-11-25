
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_campus_feedback/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CampusFeedbackApp());

    // Verify that our app starts correctly.
    expect(find.text('Flutter Campus Feedback'), findsOneWidget);
    expect(find.text('Formulir Feedback Mahasiswa'), findsOneWidget);
  });
}
