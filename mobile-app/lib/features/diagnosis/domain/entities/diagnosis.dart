import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';

/// A diagnosis saved on the phone. `id` is a UUID made on the phone, so
/// syncing it more than once is safe.
class Diagnosis {
  const Diagnosis({
    required this.id,
    required this.deviceId,
    required this.prediction,
    required this.capturedAt,
    required this.imagePath,
    this.syncState = SyncState.pending,
    this.rejectReason,
    this.secondOpinion,
  });

  final String id;
  final String deviceId;
  final Prediction prediction;
  final DateTime capturedAt;

  /// Local photo path (an asset path while the app runs on mock data).
  final String imagePath;
  final SyncState syncState;

  /// Server reason when [syncState] is rejected.
  final String? rejectReason;

  /// Server prediction, when the user asked for a second opinion.
  final Prediction? secondOpinion;

  DiagnosisCondition get condition => prediction.top.condition;
  DiagnosisStatus get status => prediction.status;
  double get confidence => prediction.top.probability;

  Diagnosis copyWith({
    SyncState? syncState,
    String? rejectReason,
    Prediction? secondOpinion,
  }) => Diagnosis(
    id: id,
    deviceId: deviceId,
    prediction: prediction,
    capturedAt: capturedAt,
    imagePath: imagePath,
    syncState: syncState ?? this.syncState,
    rejectReason: rejectReason ?? this.rejectReason,
    secondOpinion: secondOpinion ?? this.secondOpinion,
  );
}
