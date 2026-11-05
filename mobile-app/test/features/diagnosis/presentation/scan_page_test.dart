import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

import '../../../helpers.dart';

void main() {
  testWidgets('S1-A online: chips, hero, three recent items', (t) async {
    await pumpApp(t);
    expect(find.text('LeafCheck'), findsOneWidget);
    expect(find.text('Model v1'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Check a potato leaf'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Today, 09:12 · 76.5%'), findsOneWidget);
    expect(find.text('Today, 09:10 · 38.9%'), findsOneWidget);
    expect(find.text('Yesterday, 16:40 · 98.1%'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text("You're offline. Diagnosis still works."), findsNothing);
    await expectAccessible(t);
    await loadImages(t);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(goldenFile('s1_a_scan_online')),
    );
  });

  testWidgets('S1-B offline: banner and Offline chip; scan still enabled', (
    t,
  ) async {
    await pumpApp(t, scenario: MockScenario.offline);
    expect(find.text("You're offline. Diagnosis still works."), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    final scan = t.widget<FilledButton>(
      find.ancestor(
        of: find.text('Scan a leaf'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(scan.onPressed, isNotNull);
    await loadImages(t);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(goldenFile('s1_b_scan_offline')),
    );
  });

  testWidgets('S1-C first run: tips instead of recent', (t) async {
    await pumpApp(t, scenario: MockScenario.firstRun);
    expect(find.text('For a good result'), findsOneWidget);
    expect(find.text('Recent'), findsNothing);
    await loadImages(t);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(goldenFile('s1_c_scan_first_run')),
    );
  });

  testWidgets('S1a: source sheet, then sample picker', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Scan a leaf'));
    await t.pumpAndSettle();
    expect(find.text('Add a leaf photo'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    await loadImages(t);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(goldenFile('s1a_a_photo_source')),
    );
    await t.tap(find.text('Use a sample photo'));
    await t.pumpAndSettle();
    expect(find.text('Choose a sample photo'), findsOneWidget);
  });

  testWidgets('See all opens History', (t) async {
    await pumpApp(t);
    await t.tap(find.text('See all'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'History'), findsOneWidget);
  });
}
