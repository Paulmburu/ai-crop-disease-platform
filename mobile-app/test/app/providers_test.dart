import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/app/di/mock_overrides.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';

void main() {
  test('every use case resolves with the mock overrides', () {
    for (final s in MockScenario.values) {
      final c = ProviderContainer(overrides: mockOverrides(s, fast: true));
      addTearDown(c.dispose);
      for (final p in [
        diagnoseLeafProvider,
        secondOpinionProvider,
        watchHistoryProvider,
        getDiagnosisProvider,
        deleteDiagnosisProvider,
        syncDiagnosesProvider,
        askAdviceProvider,
        checkForUpdateProvider,
        downloadAndActivateProvider,
        rollbackModelProvider,
        updateSettingsProvider,
        watchBackendStatusProvider,
        runSpeedTestProvider,
      ]) {
        expect(c.read(p), isNotNull);
      }
    }
  });

  test('an unbound port fails loudly', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(() => c.read(diagnoseLeafProvider), throwsA(anything));
  });
}
