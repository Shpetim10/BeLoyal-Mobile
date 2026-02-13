import 'package:flutter_test/flutter_test.dart';
import 'package:besahub_app/main.dart';

void main() {
  testWidgets('BesaHub app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const BesaHubApp());
    // Verify login page loads.
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
