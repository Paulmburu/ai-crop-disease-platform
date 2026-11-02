import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/repositories/ports.dart';

/// Classify a photo on the phone, save it locally (pending sync), return it.
/// The diagnosis is stored before it is shown, so nothing is lost on a crash.
class DiagnoseLeaf {
  const DiagnoseLeaf({
    required this.classifier,
    required this.repository,
    required this.clock,
    required this.newId,
    required this.deviceId,
  });

  final Classifier classifier;
  final DiagnosisRepository repository;
  final Clock clock;
  final String Function() newId;
  final String deviceId;

  Future<Result<Diagnosis>> call(String imagePath) async {
    final result = await classifier.classify(imagePath);
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final prediction):
        final d = Diagnosis(
          id: newId(),
          deviceId: deviceId,
          prediction: prediction,
          capturedAt: clock(),
          imagePath: imagePath,
        );
        await repository.save(d);
        return Ok(d);
    }
  }
}

/// Ask the server classifier for the same photo and keep its answer.
class SecondOpinion {
  const SecondOpinion({required this.server, required this.repository});

  final Classifier server;
  final DiagnosisRepository repository;

  Future<Result<Diagnosis>> call(Diagnosis d) async {
    final r = await server.classify(d.imagePath);
    switch (r) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final p):
        final updated = d.copyWith(secondOpinion: p);
        await repository.save(updated);
        return Ok(updated);
    }
  }
}

class WatchHistory {
  const WatchHistory(this.repository);
  final DiagnosisRepository repository;
  Stream<List<Diagnosis>> call() => repository.watchAll();
}

class GetDiagnosis {
  const GetDiagnosis(this.repository);
  final DiagnosisRepository repository;

  Future<Result<Diagnosis>> call(String id) async {
    final d = await repository.get(id);
    return d == null
        ? Err(Invalid(code: 'not_found', detail: 'No diagnosis $id'))
        : Ok(d);
  }
}

class DeleteDiagnosis {
  const DeleteDiagnosis(this.repository);
  final DiagnosisRepository repository;
  Future<void> call(String id) => repository.delete(id);
}

class SyncDiagnoses {
  const SyncDiagnoses(this.service);
  final SyncService service;
  Future<Result<int>> call() => service.syncPending();
}

/// Counts used by History and Diagnostics.
int pendingCount(List<Diagnosis> all) =>
    all.where((d) => d.syncState == SyncState.pending).length;
