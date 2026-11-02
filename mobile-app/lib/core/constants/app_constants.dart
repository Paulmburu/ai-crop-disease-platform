/// Rules and limits shared across features. Visual values live in `ui/theme/`.
abstract final class AppConstants {
  /// Analyzing stays on screen at least this long so the scan reads on stage.
  static const minAnalyzingHold = Duration(milliseconds: 600);

  /// Diagnoses fetched per history page.
  static const historyPageSize = 50;

  /// Recent diagnoses shown on the Scan screen.
  static const recentCount = 3;

  /// Advice question length, same limits as go-backend.
  static const minQuestionLength = 3;
  static const maxQuestionLength = 500;

  /// Diagnoses sent per sync request (server limit).
  static const maxSyncBatch = 500;

  /// Runs in the on-device speed test.
  static const speedTestRuns = 100;

  /// How long a `/ready` probe may take before the app treats itself as offline.
  static const readyTimeout = Duration(seconds: 2);
}
