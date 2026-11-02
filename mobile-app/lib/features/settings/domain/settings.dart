import 'package:leafcheck/core/enums/connectivity_status.dart';

enum ThemePreference { light, dark, system }

class AppSettings {
  const AppSettings({
    required this.serverUrl,
    required this.deviceId,
    this.theme = ThemePreference.light,
    this.reduceMotion = false,
    this.hasAccessKey = true,
    this.onboarded = true,
  });

  final String serverUrl;
  final String deviceId;
  final ThemePreference theme;
  final bool reduceMotion;

  /// Whether a key is stored (the key itself never leaves secure storage).
  final bool hasAccessKey;

  /// Onboarding (S8) has been completed or skipped.
  final bool onboarded;

  AppSettings copyWith({
    ThemePreference? theme,
    bool? reduceMotion,
    bool? onboarded,
  }) => AppSettings(
    serverUrl: serverUrl,
    deviceId: deviceId,
    theme: theme ?? this.theme,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    hasAccessKey: hasAccessKey,
    onboarded: onboarded ?? this.onboarded,
  );
}

enum ServiceName { server, database, diagnosis, advice }

class ServiceStatus {
  const ServiceStatus(this.name, {required this.ok, this.latencyMs});
  final ServiceName name;
  final bool ok;
  final int? latencyMs;
}

/// Result of the last `GET /ready` probe.
class BackendStatus {
  const BackendStatus({
    required this.connectivity,
    required this.services,
    required this.checkedAt,
  });

  final ConnectivityStatus connectivity;
  final List<ServiceStatus> services;
  final DateTime checkedAt;

  bool get online => connectivity == ConnectivityStatus.online;
  bool isUp(ServiceName n) =>
      online && services.any((s) => s.name == n && s.ok);
}

class BenchmarkResult {
  const BenchmarkResult({
    required this.p50Ms,
    required this.p95Ms,
    required this.runs,
  });
  final double p50Ms;
  final double p95Ms;
  final int runs;
}

abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}

abstract interface class BackendStatusSource {
  /// Current status; emits again after [refresh] or a connectivity change.
  Stream<BackendStatus> watch();
  Future<BackendStatus> refresh();
}

abstract interface class Benchmark {
  /// Emits completed run counts, then returns the result.
  Future<BenchmarkResult> run(int runs, {void Function(int done)? onProgress});
}
