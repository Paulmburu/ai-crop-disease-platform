import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';

/// Exact values from the designs (UI_IMPLEMENTATION §4).
abstract final class DiagnosisMockData {
  static const deviceId = 'a3f1c2d4-7e21-4b8a-9c3d-5f6e7a8b9b7e';
  static const modelVersion = 'v1';
  static const threshold = 0.5;
  static const onDeviceMs = 1.9;

  // Asset paths are repeated here (not imported from ui/) because
  // infrastructure must not depend on ui/.
  static const lateBlightPhoto = 'assets/images/leaf_late_blight.jpg';
  static const earlyBlightPhoto = 'assets/images/leaf_early_blight.jpg';
  static const healthyPhoto = 'assets/images/leaf_healthy.jpg';
  static const blurryPhoto = 'assets/images/leaf_blurry.jpg';

  static Prediction prediction(
    List<(DiagnosisCondition, double)> scores, {
    PredictionSource source = PredictionSource.onDevice,
    double latencyMs = onDeviceMs,
  }) => Prediction(
    scores: [for (final (c, p) in scores) (condition: c, probability: p)],
    threshold: threshold,
    modelVersion: modelVersion,
    latencyMs: latencyMs,
    source: source,
  );

  static final Prediction lateBlight = prediction([
    (DiagnosisCondition.lateBlight, 0.765),
    (DiagnosisCondition.earlyBlight, 0.189),
    (DiagnosisCondition.healthy, 0.046),
  ]);
  static final Prediction healthy = prediction([
    (DiagnosisCondition.healthy, 0.981),
    (DiagnosisCondition.earlyBlight, 0.012),
    (DiagnosisCondition.lateBlight, 0.007),
  ]);
  static final Prediction earlyBlight = prediction([
    (DiagnosisCondition.earlyBlight, 0.884),
    (DiagnosisCondition.lateBlight, 0.093),
    (DiagnosisCondition.healthy, 0.023),
  ]);
  static final Prediction uncertain = prediction([
    (DiagnosisCondition.earlyBlight, 0.389),
    (DiagnosisCondition.lateBlight, 0.314),
    (DiagnosisCondition.healthy, 0.297),
  ]);

  /// Server second opinion for the late-blight photo (S3-E).
  static final Prediction serverLateBlight = prediction(
    [
      (DiagnosisCondition.lateBlight, 0.812),
      (DiagnosisCondition.earlyBlight, 0.151),
      (DiagnosisCondition.healthy, 0.037),
    ],
    source: PredictionSource.server,
    latencyMs: 312,
  );

  /// Photo → on-device result.
  static Prediction forPhoto(String path) => switch (path) {
    lateBlightPhoto => lateBlight,
    earlyBlightPhoto => earlyBlight,
    healthyPhoto => healthy,
    _ => uncertain,
  };

  static const clockRejectReason =
      "The phone's clock was ahead by more than a day. "
      'Check the date and time settings.';

  /// History seen in S1-A / S5-A, relative to [now] (Today, Yesterday, …).
  static List<Diagnosis> history(DateTime now, MockScenario scenario) {
    if (scenario == MockScenario.firstRun) return const [];
    DateTime at(int daysAgo, int h, int m) =>
        DateTime(now.year, now.month, now.day - daysAgo, h, m);
    Diagnosis d(
      String id,
      Prediction p,
      String photo,
      DateTime t,
      SyncState s, [
      String? reason,
    ]) => Diagnosis(
      id: id,
      deviceId: deviceId,
      prediction: p,
      capturedAt: t,
      imagePath: photo,
      syncState: s,
      rejectReason: reason,
    );
    final late91 = prediction(
      [
        (DiagnosisCondition.lateBlight, 0.917),
        (DiagnosisCondition.earlyBlight, 0.061),
        (DiagnosisCondition.healthy, 0.022),
      ],
      source: PredictionSource.server,
      latencyMs: 298,
    );
    final healthy95 = prediction([
      (DiagnosisCondition.healthy, 0.95),
      (DiagnosisCondition.earlyBlight, 0.032),
      (DiagnosisCondition.lateBlight, 0.018),
    ]);
    return [
      d('d-0912', lateBlight, lateBlightPhoto, at(0, 9, 12), SyncState.pending),
      d('d-0910', uncertain, blurryPhoto, at(0, 9, 10), SyncState.pending),
      d('d-1640', healthy, healthyPhoto, at(1, 16, 40), SyncState.synced),
      d(
        'd-1105',
        earlyBlight,
        earlyBlightPhoto,
        at(3, 11, 5),
        SyncState.synced,
      ),
      d('d-1058', late91, lateBlightPhoto, at(3, 10, 58), SyncState.synced),
      d(
        'd-1051',
        healthy95,
        healthyPhoto,
        at(3, 10, 51),
        SyncState.rejected,
        clockRejectReason,
      ),
    ];
  }
}
