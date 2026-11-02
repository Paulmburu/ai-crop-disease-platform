import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';

/// Copy used by the diagnosis pages (Scan, Analyzing, Result, History).
abstract final class DiagnosisStrings {
  // Scan
  static const heroTitle = 'Check a potato leaf';
  static const heroBody =
      'Works without internet. Fill the frame with one leaf, in daylight.';
  static const recent = 'Recent';
  static const tipsTitle = 'For a good result';
  static const tipDaylight = 'Use daylight, avoid strong shadows';
  static const tipOneLeaf = 'One leaf, filling most of the frame';
  static const tipSteady = 'Hold still until the photo is sharp';
  static const help = 'Help';

  // Photo source
  static const addPhoto = 'Add a leaf photo';
  static const takePhoto = 'Take photo';
  static const fromGallery = 'Choose from gallery';
  static const pickDemoPhoto = 'Choose a sample photo';

  // Analyzing
  static const analyzing = 'Checking the leaf…';
  static const analyzingSub = 'On this phone · no internet needed';
  static const analyzeFailed = "Couldn't check this photo";
  static const close = 'Close';

  // Result
  static const resultTitle = 'Result';
  static const confidence = 'Confidence';
  static const bestGuess = 'Best guess';
  static const meaningTitle = 'What this means';
  static const notSureBody =
      "The photo isn't clear enough for a reliable answer.";
  static const tryAgainWith = 'Try again with';
  static const retakeDaylight = 'Daylight, no harsh shadow';
  static const retakeOneLeaf = 'One leaf filling the frame';
  static const retakeSharp = 'A sharp, steady photo';
  static const retakePhoto = 'Retake photo';
  static const askServer = 'Ask the server for a second opinion';
  static const secondOpinion = 'Second opinion';
  static const thisPhone = 'This phone';
  static const bothAgree = 'Both agree';
  static const disagree = 'Results differ';
  static const syncRejectedTitle = "Couldn't sync this diagnosis";
  static const deleteTitle = 'Delete this diagnosis?';
  static const deleteBody =
      'It is removed from this phone. A copy already synced stays on the '
      'server.';
  static const secondOpinionOffline = 'A second opinion needs internet.';
  static const potatoNoDisease = 'Potato · no disease found';

  static String aboveThreshold(String t) => 'Above the $t threshold';
  static String belowThreshold(String t) => 'Below the $t threshold';

  /// "On-device · 1.9 ms · Model v1".
  static String meta(String source, String ms, String model) =>
      '$source · $ms · $model';

  /// "312 ms over Wi-Fi" (server) / "1.9 ms" (phone).
  static String serverLatency(String ms) => '$ms over Wi-Fi';

  static String pathogen(DiagnosisCondition c) => switch (c) {
    DiagnosisCondition.earlyBlight => 'Alternaria solani',
    DiagnosisCondition.lateBlight => 'Phytophthora infestans',
    DiagnosisCondition.healthy => '',
  };

  static String meaning(DiagnosisCondition c) => switch (c) {
    DiagnosisCondition.lateBlight =>
      'Late blight spreads fast in cool, wet weather and can destroy a field '
          'within days. Act today.',
    DiagnosisCondition.earlyBlight =>
      'A common fungal disease that starts on older, lower leaves. Remove '
          'badly affected leaves and keep foliage dry.',
    DiagnosisCondition.healthy =>
      'No signs of early or late blight on this leaf. Keep checking your '
          'plants every week.',
  };

  // History
  static const historyTitle = 'History';
  static const syncNow = 'Sync now';
  static const emptyTitle = 'No diagnoses yet';
  static const emptyBody =
      'Scan a leaf and it will appear here, even without internet.';
  static const syncOffline = 'Sync needs internet. Diagnoses stay saved.';

  /// "2 waiting to sync · Last sync today 08:55".
  static String syncSummary(int pending, String? lastSync) => [
    if (pending > 0) '$pending waiting to sync' else 'All synced',
    if (lastSync != null) 'Last sync $lastSync',
  ].join(' · ');

  static String syncingCount(int n) => 'Syncing $n diagnoses…';
  static String syncedCount(int n) =>
      n == 1 ? 'Synced 1 diagnosis' : 'Synced $n diagnoses';

  // Status
  static const notSure = 'Not sure';

  static String name(DiagnosisCondition c) => switch (c) {
    DiagnosisCondition.earlyBlight => 'Early blight',
    DiagnosisCondition.lateBlight => 'Late blight',
    DiagnosisCondition.healthy => 'Healthy',
  };

  /// "Today, 09:12 · 76.5%".
  static String tileSubtitle(String when, String percent) => '$when · $percent';
}
