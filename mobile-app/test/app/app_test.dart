import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('app starts on Scan; tabs switch; pushed routes go back', (
    t,
  ) async {
    await pumpApp(t);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'LeafCheck'), findsOneWidget);

    await t.tap(find.text('History').last);
    await t.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'History'), findsOneWidget);

    await t.tap(find.text('Settings').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Diagnosis model'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Diagnosis model'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });
}
