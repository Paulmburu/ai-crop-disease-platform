import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';

/// Thin use cases over the port; they are the only thing presentation calls.
class CheckForUpdate {
  const CheckForUpdate(this.repository);
  final ModelUpdateRepository repository;
  Future<Result<ModelRelease?>> call() => repository.check();
}

class DownloadAndActivate {
  const DownloadAndActivate(this.repository);
  final ModelUpdateRepository repository;

  /// Emits progress; the last event is followed by activation.
  Stream<DownloadProgress> download(ModelRelease r) => repository.download(r);
  Future<Result<ModelRelease>> activate(ModelRelease r) =>
      repository.activate(r);
}

class RollbackModel {
  const RollbackModel(this.repository);
  final ModelUpdateRepository repository;
  Future<Result<ModelRelease>> call() => repository.rollback();
}
