import 'dart:async';

import 'package:leafcheck/core/enums/connectivity_status.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';

class MockSettingsRepository implements SettingsRepository {
  MockSettingsRepository({bool onboarded = true})
    : _s = AppSettings(
        serverUrl: 'http://10.0.2.2:8080',
        deviceId: 'a3f1c2d4-7e21-4b8a-9c3d-5f6e7a8b9b7e',
        onboarded: onboarded,
      );

  AppSettings _s;

  @override
  AppSettings load() => _s;

  @override
  Future<void> save(AppSettings settings) async => _s = settings;
}

/// Scenario-driven `/ready`: online with the advice service down in
/// `adviceDown`, offline in `offline`.
class MockBackendStatusSource implements BackendStatusSource {
  MockBackendStatusSource(this.scenario, {required DateTime Function() clock})
    : _clock = clock;

  final MockScenario scenario;
  final DateTime Function() _clock;
  final _changes = StreamController<BackendStatus>.broadcast();

  BackendStatus _status() {
    final offline = scenario == MockScenario.offline;
    return BackendStatus(
      connectivity: offline
          ? ConnectivityStatus.offline
          : ConnectivityStatus.online,
      services: offline
          ? const []
          : [
              const ServiceStatus(ServiceName.server, ok: true, latencyMs: 24),
              const ServiceStatus(ServiceName.database, ok: true),
              const ServiceStatus(ServiceName.diagnosis, ok: true),
              ServiceStatus(
                ServiceName.advice,
                ok: scenario != MockScenario.adviceDown,
              ),
            ],
      checkedAt: _clock(),
    );
  }

  @override
  Stream<BackendStatus> watch() async* {
    yield _status();
    yield* _changes.stream;
  }

  @override
  Future<BackendStatus> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final s = _status();
    _changes.add(s);
    return s;
  }
}

/// Canned speed test: 1.9 ms p50 and p95 (benchmarks/results.md D2).
class MockBenchmark implements Benchmark {
  MockBenchmark({this.perRun = const Duration(milliseconds: 25)});
  final Duration perRun;

  @override
  Future<BenchmarkResult> run(
    int runs, {
    void Function(int done)? onProgress,
  }) async {
    for (var i = 1; i <= runs; i++) {
      await Future<void>.delayed(perRun);
      onProgress?.call(i);
    }
    return BenchmarkResult(p50Ms: 1.9, p95Ms: 1.9, runs: runs);
  }
}
