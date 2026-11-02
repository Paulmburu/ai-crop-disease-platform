import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/advice/infrastructure/mock/mock_advice_repository.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/mock/diagnosis_mock_data.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/mock/mock_diagnosis_adapters.dart';
import 'package:leafcheck/features/model_update/infrastructure/mock/mock_model_update_repository.dart';
import 'package:leafcheck/features/settings/infrastructure/mock/mock_settings_adapters.dart';

/// Binds every port to its mock for [scenario] (UI_IMPLEMENTATION §4).
/// [fast] removes artificial delays (tests).
List<Override> mockOverrides(
  MockScenario scenario, {
  Clock clock = systemClock,
  bool fast = false,
}) {
  final repo = MockDiagnosisRepository(
    DiagnosisMockData.history(clock(), scenario),
  );
  Duration d(Duration real) => fast ? Duration.zero : real;
  return [
    scenarioProvider.overrideWithValue(scenario),
    clockProvider.overrideWithValue(clock),
    diagnosisRepositoryProvider.overrideWithValue(repo),
    classifierProvider.overrideWithValue(
      MockClassifier(scenario, delay: d(const Duration(milliseconds: 900))),
    ),
    serverClassifierProvider.overrideWithValue(
      MockServerClassifier(scenario, delay: d(const Duration(seconds: 1))),
    ),
    syncServiceProvider.overrideWithValue(
      MockSyncService(
        repo,
        scenario,
        clock: clock,
        delay: d(const Duration(milliseconds: 1500)),
      ),
    ),
    adviceRepositoryProvider.overrideWithValue(
      MockAdviceRepository(scenario, delay: d(const Duration(seconds: 3))),
    ),
    modelUpdateRepositoryProvider.overrideWithValue(
      MockModelUpdateRepository(
        scenario,
        clock: clock,
        step: d(const Duration(milliseconds: 150)),
      ),
    ),
    settingsRepositoryProvider.overrideWithValue(
      MockSettingsRepository(onboarded: scenario != MockScenario.onboarding),
    ),
    backendStatusSourceProvider.overrideWithValue(
      MockBackendStatusSource(scenario, clock: clock),
    ),
    benchmarkProvider.overrideWithValue(
      MockBenchmark(perRun: d(const Duration(milliseconds: 25))),
    ),
  ];
}
