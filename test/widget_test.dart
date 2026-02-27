// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cooklevel_app/main.dart';
import 'package:cooklevel_app/providers/auth_provider.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final authProvider = AuthProvider();
    await tester.pumpWidget(CappyApp(authProvider: authProvider));

    // Verify that the app root is rendered.
    expect(find.byType(CappyApp), findsOneWidget);
  });
}
