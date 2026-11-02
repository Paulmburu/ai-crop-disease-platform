import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/advice/application/ask_advice.dart';
import 'package:leafcheck/features/advice/domain/advice.dart';
import 'package:leafcheck/features/diagnosis/application/use_cases.dart';
import 'package:leafcheck/features/diagnosis/domain/repositories/ports.dart';
import 'package:leafcheck/features/library/application/get_disease_notes.dart';
import 'package:leafcheck/features/library/domain/disease_note.dart';
import 'package:leafcheck/features/library/infrastructure/asset_disease_library.dart';
import 'package:leafcheck/features/model_update/application/model_update_use_cases.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';
import 'package:leafcheck/features/settings/application/settings_use_cases.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';

/// Composition root. Ports are declared here and bound in `main` through
/// overrides: mock adapters today (mock_overrides.dart), real ones later.
/// Pages and controllers read only the use-case providers below.

Never _unbound(String port) =>
    throw UnimplementedError('$port is not bound; see mock_overrides.dart');

// ── Environment ──────────────────────────────────────────────────────────
final scenarioProvider = Provider<MockScenario>((_) => MockScenario.online);
final clockProvider = Provider<Clock>((_) => systemClock);
final idGeneratorProvider = Provider<String Function()>(
  // ponytail: time-based ids for mock data; real UUID v4 (package uuid) in F1.
  (_) =>
      () => 'd-${DateTime.now().microsecondsSinceEpoch}',
);

// ── Ports ────────────────────────────────────────────────────────────────
final diagnosisRepositoryProvider = Provider<DiagnosisRepository>(
  (_) => _unbound('DiagnosisRepository'),
);
final classifierProvider = Provider<Classifier>((_) => _unbound('Classifier'));
final serverClassifierProvider = Provider<Classifier>(
  (_) => _unbound('server Classifier'),
);
final syncServiceProvider = Provider<SyncService>(
  (_) => _unbound('SyncService'),
);
final adviceRepositoryProvider = Provider<AdviceRepository>(
  (_) => _unbound('AdviceRepository'),
);
final modelUpdateRepositoryProvider = Provider<ModelUpdateRepository>(
  (_) => _unbound('ModelUpdateRepository'),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (_) => _unbound('SettingsRepository'),
);
final backendStatusSourceProvider = Provider<BackendStatusSource>(
  (_) => _unbound('BackendStatusSource'),
);
final benchmarkProvider = Provider<Benchmark>((_) => _unbound('Benchmark'));

// ── Use cases ────────────────────────────────────────────────────────────
final Provider<DiagnoseLeaf> diagnoseLeafProvider = Provider(
  (ref) => DiagnoseLeaf(
    classifier: ref.watch(classifierProvider),
    repository: ref.watch(diagnosisRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    deviceId: ref.watch(settingsRepositoryProvider).load().deviceId,
  ),
);
final Provider<SecondOpinion> secondOpinionProvider = Provider(
  (ref) => SecondOpinion(
    server: ref.watch(serverClassifierProvider),
    repository: ref.watch(diagnosisRepositoryProvider),
  ),
);
final Provider<WatchHistory> watchHistoryProvider = Provider(
  (ref) => WatchHistory(ref.watch(diagnosisRepositoryProvider)),
);
final Provider<GetDiagnosis> getDiagnosisProvider = Provider(
  (ref) => GetDiagnosis(ref.watch(diagnosisRepositoryProvider)),
);
final Provider<DeleteDiagnosis> deleteDiagnosisProvider = Provider(
  (ref) => DeleteDiagnosis(ref.watch(diagnosisRepositoryProvider)),
);
final Provider<SyncDiagnoses> syncDiagnosesProvider = Provider(
  (ref) => SyncDiagnoses(ref.watch(syncServiceProvider)),
);
final Provider<AskAdvice> askAdviceProvider = Provider(
  (ref) => AskAdvice(ref.watch(adviceRepositoryProvider)),
);
final Provider<CheckForUpdate> checkForUpdateProvider = Provider(
  (ref) => CheckForUpdate(ref.watch(modelUpdateRepositoryProvider)),
);
final Provider<DownloadAndActivate> downloadAndActivateProvider = Provider(
  (ref) => DownloadAndActivate(ref.watch(modelUpdateRepositoryProvider)),
);
final Provider<RollbackModel> rollbackModelProvider = Provider(
  (ref) => RollbackModel(ref.watch(modelUpdateRepositoryProvider)),
);
final Provider<UpdateSettings> updateSettingsProvider = Provider(
  (ref) => UpdateSettings(ref.watch(settingsRepositoryProvider)),
);
final Provider<WatchBackendStatus> watchBackendStatusProvider = Provider(
  (ref) => WatchBackendStatus(ref.watch(backendStatusSourceProvider)),
);
final Provider<RunSpeedTest> runSpeedTestProvider = Provider(
  (ref) => RunSpeedTest(ref.watch(benchmarkProvider)),
);

/// Active on-device model (version shown on Scan, Result and Settings).
final activeModelProvider = Provider<ModelRelease>(
  (ref) => ref.watch(modelUpdateRepositoryProvider).active,
);

/// Bundled disease notes (real offline content, no mock needed).
final diseaseLibraryProvider = Provider<DiseaseLibrary>(
  (_) => AssetDiseaseLibrary(rootBundle.loadString),
);
final getDiseaseNotesProvider = Provider(
  (ref) => GetDiseaseNotes(ref.watch(diseaseLibraryProvider)),
);
