import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/app.dart';
import 'package:leafcheck/app/di/mock_overrides.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

/// UI phase: every port is bound to its mock. Pick a design state with
/// `flutter run --dart-define=SCENARIO=offline` (see MockScenario).
void main() => runApp(
  ProviderScope(
    overrides: mockOverrides(MockScenario.fromEnvironment),
    child: const App(),
  ),
);
