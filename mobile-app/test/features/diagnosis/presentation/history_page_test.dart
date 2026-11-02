import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

import '../../../helpers.dart';

void main() {
  Future<void> openHistory(
    WidgetTester t, {
    MockScenario scenario = MockScenario.online,
    bool fast = true,
  }) async {
    await pumpApp(t, scenario: scenario, fast: fast);
    await t.tap(find.text('History').last);
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('S5-A grouped by day with sync summary', (t) async {
    await openHistory(t);
    expect(
      find.text('2 waiting to sync · Last sync today 08:55'),
      findsOneWidget,
    );
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('27 Oct 2026'), findsOneWidget);
    expect(find.text('09:12 · 76.5% · On-device'), findsOneWidget);
    expect(find.text('10:58 · 91.7% · Server'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    await expectAccessible(t);
    await expectScreen(t, 's5_a_history_1');
  });

  testWidgets('S5-B syncing: chips spin, then Synced + snackbar', (t) async {
    await openHistory(t, fast: false);
    await t.tap(find.byTooltip('Sync now'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Syncing 2 diagnoses…'), findsOneWidget);
    expect(find.text('Syncing'), findsNWidgets(2));
    await expectScreen(t, 's5_b_history_syncing');
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Synced 2 diagnoses'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('S5-C empty', (t) async {
    await openHistory(t, scenario: MockScenario.firstRun);
    expect(find.text('No diagnoses yet'), findsOneWidget);
    expect(find.byTooltip('Sync now'), findsNothing);
    await expectScreen(t, 's5_c_history_empty');
    await t.tap(find.text('Scan a leaf'));
    await t.pumpAndSettle();
    expect(find.text('Check a potato leaf'), findsOneWidget);
  });

  testWidgets('offline sync explains instead of failing silently', (t) async {
    await openHistory(t, scenario: MockScenario.offline);
    await t.tap(find.byTooltip('Sync now'));
    await t.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Sync needs internet. Diagnoses stay saved.'),
      findsOneWidget,
    );
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('tile opens Result', (t) async {
    await openHistory(t);
    await t.tap(find.text('10:58 · 91.7% · Server'));
    await t.pumpAndSettle();
    expect(find.text('91.7%'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
