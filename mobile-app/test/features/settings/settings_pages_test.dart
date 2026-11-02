import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

import '../../helpers.dart';

void main() {
  Future<void> openSettings(
    WidgetTester t, {
    MockScenario scenario = MockScenario.online,
  }) async {
    await pumpApp(t, scenario: scenario);
    await t.tap(find.text('Settings').last);
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('S7-A settings', (t) async {
    await openSettings(t);
    expect(find.text('Diagnosis model'), findsOneWidget);
    expect(find.text('v1 · up to date'), findsOneWidget);
    expect(
      find.text('http://10.0.2.2:8080 · Android emulator'),
      findsOneWidget,
    );
    expect(find.text('All services working'), findsOneWidget);
    expect(find.text('a3f1c2d4-…-9b7e'), findsOneWidget);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    await expectAccessible(t);
    await expectScreen(t, 's7_a_settings');
  });

  testWidgets('theme switch applies app-wide; reduce motion toggles', (
    t,
  ) async {
    await openSettings(t);
    await t.tap(find.text('Dark'));
    await t.pumpAndSettle();
    final ctx = t.element(find.text('Theme'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    await expectScreen(t, 's7_a_settings_dark');
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('S7-B diagnostics with advice down', (t) async {
    await openSettings(t, scenario: MockScenario.adviceDown);
    expect(find.text('1 issue'), findsOneWidget);
    await t.tap(find.text('Diagnostics'));
    await t.pumpAndSettle();
    expect(find.text('OK · 24 ms'), findsOneWidget);
    expect(find.text('Down'), findsOneWidget);
    expect(find.text('Checked 10:24 · http://10.0.2.2:8080'), findsOneWidget);
    expect(find.text('Today, 08:55'), findsOneWidget);
    expect(find.text('v1 · 9.0 MB'), findsOneWidget);
    await expectScreen(t, 's7_b_diagnostics_2');
  });

  testWidgets('S7-C speed test runs and shows p50/p95', (t) async {
    await openSettings(t);
    await t.tap(find.text('Diagnostics'));
    await t.pumpAndSettle();
    await t.tap(find.text('Run speed test'));
    await t.pumpAndSettle();
    expect(
      find.text(
        '100 diagnoses of the same photo on this phone, '
        'no internet.',
      ),
      findsOneWidget,
    );
    expect(find.text('1.9'), findsNWidgets(2));
    expect(find.text('1.9 ms'), findsOneWidget);
    expect(find.text('≈ 34 s'), findsOneWidget);
    await expectScreen(t, 's7_c_speed_test');
  });
}
