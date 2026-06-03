import 'package:flutter_test/flutter_test.dart';
import 'package:farmtech_agridirect/main.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AgriDirectApp());

    // Verify that Splash Screen shows the app name/branding
    expect(find.text('Farmtech'), findsOneWidget);
    expect(find.text('AgriDirect Nepal'), findsOneWidget);
  });
}
