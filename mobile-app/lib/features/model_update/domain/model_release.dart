import 'package:leafcheck/core/result/result.dart';

enum ModelUpdatePhase {
  upToDate,
  available,
  downloading,
  installed,
  checkFailed,
}

/// A published model (go-backend `/model-releases`).
class ModelRelease {
  const ModelRelease({
    required this.version,
    required this.sizeBytes,
    required this.sha256,
    required this.classLabels,
    required this.threshold,
    required this.date,
  });

  final String version;
  final int sizeBytes;
  final String sha256;
  final List<String> classLabels;
  final double threshold;

  /// Installed date for the active model, published date for a candidate.
  final DateTime date;
}

class DownloadProgress {
  const DownloadProgress(this.received, this.total);
  final int received;
  final int total;
  double get fraction => total == 0 ? 0 : received / total;
  bool get done => received >= total;
}

abstract interface class ModelUpdateRepository {
  ModelRelease get active;

  /// Previous model kept for rollback, if any.
  ModelRelease? get previous;

  /// A newer release, or null when up to date.
  Future<Result<ModelRelease?>> check();
  Stream<DownloadProgress> download(ModelRelease release);

  /// Verifies sha256 and switches models. `ChecksumMismatch` keeps the old one.
  Future<Result<ModelRelease>> activate(ModelRelease release);
  Future<Result<ModelRelease>> rollback();
  DateTime get checkedAt;
}
