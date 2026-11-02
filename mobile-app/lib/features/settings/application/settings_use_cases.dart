import 'package:leafcheck/features/settings/domain/settings.dart';

class UpdateSettings {
  const UpdateSettings(this.repository);
  final SettingsRepository repository;
  Future<void> call(AppSettings s) => repository.save(s);
}

class WatchBackendStatus {
  const WatchBackendStatus(this.source);
  final BackendStatusSource source;
  Stream<BackendStatus> call() => source.watch();
  Future<BackendStatus> refresh() => source.refresh();
}

class RunSpeedTest {
  const RunSpeedTest(this.benchmark);
  final Benchmark benchmark;
  Future<BenchmarkResult> call(
    int runs, {
    void Function(int done)? onProgress,
  }) => benchmark.run(runs, onProgress: onProgress);
}
