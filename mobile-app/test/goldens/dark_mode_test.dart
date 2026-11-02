import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

import '../helpers.dart';

/// U13: dark variants of the key screens, each checked for WCAG contrast.
void main() {
  Future<void> darkApp(WidgetTester t, {bool fast = true}) async {
    await pumpApp(t, fast: fast);
    await useDarkTheme(t);
  }

  Future<void> check(WidgetTester t, String name) async {
    await expectLater(t, meetsGuideline(textContrastGuideline));
    await expectScreen(t, 'dark/$name');
  }

  testWidgets('S1-A dark', (t) async {
    await darkApp(t);
    expect(
      Theme.of(t.element(find.text('LeafCheck'))).brightness,
      Brightness.dark,
    );
    await check(t, 's1_a_scan_online');
  });

  testWidgets('S3-A and S3-D dark', (t) async {
    await darkApp(t);
    await pushRoute(t, '/diagnosis/d-0912');
    await check(t, 's3_a_result_late_blight');
    await t.pageBack();
    await t.pumpAndSettle();
    await pushRoute(t, '/diagnosis/d-0910');
    await check(t, 's3_d_result_not_sure');
  });

  testWidgets('S4-C dark', (t) async {
    await darkApp(t);
    await pushRoute(t, '/diagnosis/d-0912');
    await t.tap(find.text('Get advice'));
    await t.pumpAndSettle();
    await t.tap(find.text('What should I do today?'));
    await t.pumpAndSettle();
    await check(t, 's4_c_advice_answer');
  });

  testWidgets('S5-A dark', (t) async {
    await darkApp(t);
    await t.tap(find.text('History').last);
    await t.pumpAndSettle();
    await check(t, 's5_a_history');
  });

  testWidgets('S6-C dark', (t) async {
    await pumpApp(t, scenario: MockScenario.updateAvailable, fast: false);
    await useDarkTheme(t);
    await pushRoute(t, '/settings/model');
    await t.tap(find.text('Check for updates'));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 400));
    }
    await t.tap(find.text('Download v2'));
    await t.pump(const Duration(milliseconds: 2550));
    await check(t, 's6_c_model_downloading');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('S7-A dark', (t) async {
    await darkApp(t);
    await t.tap(find.text('Settings').last);
    await t.pumpAndSettle();
    await check(t, 's7_a_settings');
  });
}
