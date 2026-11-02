import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

import '../../helpers.dart';

void main() {
  testWidgets('S8-A → B → C → Scan; not shown again', (t) async {
    await pumpApp(t, scenario: MockScenario.onboarding);
    expect(find.text('Works in the field, without internet'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await expectAccessible(t);
    await expectScreen(t, 's8_a_onboarding_1');

    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    expect(find.text('One leaf, daylight, steady'), findsOneWidget);
    expect(find.text('Hard to read'), findsOneWidget);
    await expectScreen(t, 's8_b_onboarding_2');

    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    expect(find.text('Your photos stay with you'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await expectScreen(t, 's8_c_onboarding_3');

    await t.tap(find.text('Start scanning'));
    await t.pumpAndSettle();
    expect(find.text('Check a potato leaf'), findsOneWidget);
  });

  testWidgets('Skip goes straight to Scan', (t) async {
    await pumpApp(t, scenario: MockScenario.onboarding);
    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();
    expect(find.text('Check a potato leaf'), findsOneWidget);
  });

  testWidgets('other scenarios start on Scan', (t) async {
    await pumpApp(t);
    expect(find.text('Works in the field, without internet'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
