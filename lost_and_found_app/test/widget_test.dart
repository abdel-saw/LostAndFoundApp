import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_app/screens/login_screen.dart';

void main() {
  testWidgets('empty login is rejected before requesting authentication', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    expect(find.text('Please enter email and password'), findsOneWidget);
  });

  testWidgets('sign-up mode can be opened and closed', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pump();
    expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pump();
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });
}
