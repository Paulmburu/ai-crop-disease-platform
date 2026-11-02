import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/app.dart';
import 'package:leafcheck/app/di/mock_overrides.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';
import 'package:leafcheck/features/settings/presentation/settings/app_settings_controller.dart';
import 'package:leafcheck/ui/theme/app_theme.dart';

/// Pumps [child] inside the app theme on a 412 x 915 phone.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool disableAnimations = false,
  bool scaffold = true,
}) async {
  tester.view
    ..physicalSize = const Size(412, 915) * shotDpr.toDouble()
    ..devicePixelRatio = shotDpr.toDouble();
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 915),
          disableAnimations: disableAnimations,
        ),
        child: scaffold ? Scaffold(body: child) : child,
      ),
    ),
  );
}

/// The accessibility checks every UI test runs.
Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

/// Typed accessors for results in tests.
extension ResultTestX<T> on Result<T> {
  T get okValue => (this as Ok<T>).value;
  Failure get errFailure => (this as Err<T>).failure;
}

/// Pumps the whole app (router, theme) on mock data for [scenario] at a
/// fixed time: 30 Oct 2026, 10:24 (the designs' status bar time).
Future<void> pumpApp(
  WidgetTester tester, {
  MockScenario scenario = MockScenario.online,
  bool disableAnimations = true,
  bool fast = true,
}) async {
  tester.view
    ..physicalSize = const Size(412, 915) * shotDpr.toDouble()
    ..devicePixelRatio = shotDpr.toDouble();
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: disableAnimations);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: mockOverrides(
        scenario,
        clock: fixedClock(designNow),
        fast: fast,
      ),
      child: const App(),
    ),
  );
  // Streams resolve, then any implicit animation started by them finishes.
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

final designNow = DateTime(2026, 10, 30, 10, 24);

/// Pumps a single page with mock providers (for key-frame goldens).
Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  MockScenario scenario = MockScenario.online,
}) async {
  tester.view
    ..physicalSize = const Size(412, 915) * shotDpr.toDouble()
    ..devicePixelRatio = shotDpr.toDouble();
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: mockOverrides(
        scenario,
        clock: fixedClock(designNow),
        fast: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: page,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pushes [location] on the app router (after [pumpApp]) and settles.
Future<void> pushRoute(WidgetTester tester, String location) async {
  final ctx = tester.element(find.byType(Navigator).first);
  unawaited(GoRouter.of(ctx).push(location));
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Slide screenshots: `flutter test --update-goldens --dart-define=SHOT_DPR=3
/// --dart-define=SHOT_DIR=/abs/dir/` re-renders every golden at 3x into
/// SHOT_DIR and leaves `test/goldens` untouched.
const shotDpr = int.fromEnvironment('SHOT_DPR', defaultValue: 1);
const _shotDir = String.fromEnvironment('SHOT_DIR');

/// Where the golden [name] is stored (see [shotDpr]).
String goldenFile(String name) =>
    '${_shotDir.isEmpty ? _goldenDir() : _shotDir}$name.png';

/// Golden of the whole screen, saved next to the other goldens.
Future<void> expectScreen(WidgetTester t, String name) async {
  await loadImages(t);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(goldenFile(name)),
  );
}

/// Decodes every on-screen image for real; under the test's fake clock they
/// would otherwise stay blank in goldens.
Future<void> loadImages(WidgetTester t) async {
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pump();
}

String _goldenDir() => '${Directory.current.path}/test/goldens/';

/// Switches the running app to the dark theme (Settings → Theme → Dark).
Future<void> useDarkTheme(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  await container
      .read(appSettingsProvider.notifier)
      .setTheme(ThemePreference.dark);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}
