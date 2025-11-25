import 'package:flutter_test/flutter_test.dart';
import 'package:profil_dosen/main.dart';

void main() {
  testWidgets('App should display dosen list', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify that the app bar is displayed
    expect(find.text('Daftar Dosen'), findsOneWidget);

    // Verify that dosen list items are displayed
    expect(find.text('Dr. Ahmad Wijaya, S.T., M.T.'), findsOneWidget);
    expect(find.text('Prof. Dr. Siti Rahayu, M.Si.'), findsOneWidget);
    expect(find.text('Rina Dewi, S.Kom., M.Kom.'), findsOneWidget);
  });
}
