import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toolkudu/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ToolKuduApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app renders without errors
    // The app should show either the login screen or home screen
    expect(find.byType(ToolKuduApp), findsOneWidget);
  });
}
