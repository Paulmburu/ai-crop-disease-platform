import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/app.dart';
import 'package:leafcheck/app/di/mock_overrides.dart';
import 'package:leafcheck/app/di/real_overrides.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

/// Real adapters by default (LiteRT, Hive, go-backend at SERVER_URL).
/// `--dart-define=SCENARIO=<name>` runs on mock data instead (design states,
/// demos without a backend); see MockScenario.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const scenario = String.fromEnvironment('SCENARIO');
  runApp(
    ProviderScope(
      overrides: scenario.isEmpty
          ? await realOverrides()
          : mockOverrides(MockScenario.fromName(scenario)),
      child: const App(),
    ),
  );
}
