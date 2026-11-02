import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

import '../../helpers.dart';

void main() {
  Future<void> open(WidgetTester t, MockScenario s, {bool fast = true}) async {
    await pumpApp(t, scenario: s, fast: fast);
    await pushRoute(t, '/settings/model');
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('S6-A up to date', (t) async {
    await open(t, MockScenario.online);
    expect(find.text('Model v1'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Early blight, Late blight, Healthy'), findsOneWidget);
    expect(find.text('9.0 MB'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('29 Oct 2026'), findsOneWidget);
    expect(find.text('83bb8785…c969b7b'), findsOneWidget);
    expect(find.text('Up to date · checked today 10:20'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    await expectAccessible(t);
    await expectScreen(t, 's6_a_model_up_to_date');
  });

  testWidgets('S6-B → C → D: update, download, installed, undo', (t) async {
    await open(t, MockScenario.updateAvailable, fast: false);
    await t.tap(find.text('Check for updates'));
    await settle(t);
    expect(find.text('Model v2 is available'), findsOneWidget);
    expect(
      find.text('9.1 MB · Same three conditions · Published 30 Oct 2026'),
      findsOneWidget,
    );
    await expectScreen(t, 's6_b_model_update_available');

    await t.tap(find.text('Download v2'));
    await t.pump(const Duration(milliseconds: 2550)); // 17 of 40 steps
    expect(find.text('Downloading model v2'), findsOneWidget);
    expect(
      find.text('Model v1 stays active until v2 is checked.'),
      findsOneWidget,
    );
    await expectScreen(t, 's6_c_model_downloading');

    await t.pump(const Duration(seconds: 5));
    await settle(t);
    expect(find.text('Model v2'), findsOneWidget);
    expect(
      find.text('Checked and installed · v1 kept as backup'),
      findsOneWidget,
    );
    expect(find.text('Model v2 is ready'), findsOneWidget);
    expect(find.text('Go back to v1'), findsOneWidget);
    await expectScreen(t, 's6_d_model_installed');

    await t.tap(find.text('Go back to v1'));
    await settle(t);
    expect(find.text('Model v1'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('S6-E checksum failure keeps v1', (t) async {
    await open(t, MockScenario.checksumFail);
    await t.tap(find.text('Check for updates'));
    await settle(t);
    await t.tap(find.text('Download v2'));
    await settle(t);
    expect(find.text("Download didn't pass the safety check"), findsOneWidget);
    expect(find.textContaining('Model v1 is still active'), findsOneWidget);
    expect(find.text('Model v1'), findsOneWidget);
    expect(
      find.text('Update available · checked today 10:24'),
      findsOneWidget,
    );
    await expectScreen(t, 's6_e_model_check_failed');
  });
}
