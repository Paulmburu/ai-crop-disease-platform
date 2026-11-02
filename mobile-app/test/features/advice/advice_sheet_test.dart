import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

import '../../helpers.dart';

void main() {
  Future<void> openSheet(
    WidgetTester t, {
    MockScenario scenario = MockScenario.online,
    bool fast = true,
  }) async {
    await pumpApp(t, scenario: scenario, fast: fast);
    await pushRoute(t, '/diagnosis/d-0912');
    await t.tap(find.text('Get advice'));
    for (var i = 0; i < 3; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('S4-A questions', (t) async {
    await openSheet(t);
    expect(find.text('Ask about late blight'), findsOneWidget);
    expect(find.text('What should I do today?'), findsOneWidget);
    expect(find.text('How does it spread?'), findsOneWidget);
    expect(find.text('Type your question'), findsOneWidget);
    await expectAccessible(t);
    await expectScreen(t, 's4_a_advice_questions');
  });

  testWidgets('S4-B loading, then S4-C answer with sources', (t) async {
    await openSheet(t, fast: false);
    await t.tap(find.text('What should I do today?'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Looking through the guides'), findsOneWidget);
    await expectScreen(t, 's4_b_advice_loading');

    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('1  Potato late blight'), findsOneWidget);
    expect(find.text('2  Potato late blight: Management'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // citation marker
    expect(find.text('Ask a follow-up'), findsOneWidget);
    await expectScreen(t, 's4_c_advice_answer');

    await t.tap(find.text('2'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('S4-D offline', (t) async {
    await openSheet(t, scenario: MockScenario.offline);
    expect(find.text('Advice needs internet'), findsOneWidget);
    expect(find.text('Ask when online'), findsOneWidget);
    expect(find.text('Type your question'), findsNothing);
    await expectScreen(t, 's4_d_advice_offline');
  });

  testWidgets('S4-E unavailable with reference', (t) async {
    await openSheet(t, scenario: MockScenario.adviceDown);
    await t.tap(find.text('What should I do today?'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Advice is unavailable right now'), findsOneWidget);
    expect(find.text('Reference: d6720fce'), findsOneWidget);
    await expectScreen(t, 's4_e_advice_unavailable');
  });

  testWidgets('close returns to Result', (t) async {
    await openSheet(t);
    await t.tap(find.byTooltip('Close'));
    await t.pumpAndSettle();
    expect(find.text('Ask about late blight'), findsNothing);
    expect(find.text('Get advice'), findsOneWidget);
  });
}
