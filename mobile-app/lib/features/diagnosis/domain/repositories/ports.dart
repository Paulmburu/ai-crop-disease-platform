import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';

/// Local store of diagnoses (Hive later).
abstract interface class DiagnosisRepository {
  /// All diagnoses, newest first; emits again on every change.
  Stream<List<Diagnosis>> watchAll();
  Future<Diagnosis?> get(String id);
  Future<void> save(Diagnosis diagnosis);
  Future<void> delete(String id);
}

/// Runs the model on a photo: on-device (LiteRT) or on the server.
abstract interface class Classifier {
  Future<Result<Prediction>> classify(String imagePath);
}

/// Uploads pending diagnoses (go-backend `POST /diagnoses:sync` later).
abstract interface class SyncService {
  /// Marks pending items as syncing, uploads them, and stores the outcome.
  /// Returns how many were synced.
  Future<Result<int>> syncPending();
  DateTime? get lastSyncAt;
}
