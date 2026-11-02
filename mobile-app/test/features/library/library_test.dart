import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/features/library/infrastructure/asset_disease_library.dart';

import '../../helpers.dart';

void main() {
  test('parses the bundled knowledge notes', () async {
    final lib = AssetDiseaseLibrary((p) => File(p).readAsString());
    final notes = await lib.all();
    expect(notes.map((n) => n.classLabel), [
      'Potato___Late_blight',
      'Potato___Early_blight',
      'Potato___healthy',
    ]);
    final late = notes.first;
    expect(late.title, 'Potato late blight');
    expect(late.sources.single, contains('ipm.ucanr.edu'));
    expect(late.section('Management'), contains('- Plant certified seed'));
    expect(late.sections.first.heading, 'Overview');
  });

  testWidgets('S9-A list and S9-B detail', (t) async {
    await pumpApp(t);
    await t.runAsync(() async {
      await pushRoute(t, '/library');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Potato diseases'), findsOneWidget);
    expect(find.text('Healthy leaf'), findsOneWidget);
    expect(
      find.textContaining('most destructive potato disease'),
      findsOneWidget,
    );
    await expectAccessible(t);
    await expectScreen(t, 's9_a_disease_library');

    await t.tap(find.text('Late blight').at(1));
    await t.pumpAndSettle();
    expect(find.text('Potato late blight'), findsOneWidget);
    expect(find.text('Phytophthora infestans'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    await expectScreen(t, 's9_b_late_blight');
    await t.scrollUntilVisible(find.text('Management'), 300);
    expect(find.text('Management'), findsOneWidget);
  });

  testWidgets('help icon on Scan opens the library', (t) async {
    await pumpApp(t);
    await t.tap(find.byTooltip('Help'));
    await t.pumpAndSettle();
    expect(find.text('Potato diseases'), findsOneWidget);
  });

  testWidgets('advice offline links to the offline note', (t) async {
    await pumpApp(t, scenario: MockScenario.offline);
    await pushRoute(t, '/diagnosis/d-0912');
    await t.tap(find.text('Get advice'));
    await t.pumpAndSettle();
    await t.tap(find.text('Read offline notes'));
    for (var i = 0; i < 2; i++) {
      await t.pumpAndSettle();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
    }
    await t.pumpAndSettle();
    expect(find.text('Potato late blight'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
