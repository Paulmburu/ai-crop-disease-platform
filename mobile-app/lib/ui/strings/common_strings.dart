/// Copy used by two or more features. Feature-only copy lives in
/// `features/<f>/presentation/strings/`.
abstract final class CommonStrings {
  static const appName = 'LeafCheck';

  // Connectivity and sync
  static const online = 'Online';
  static const offline = 'Offline';
  static const pending = 'Pending';
  static const syncing = 'Syncing';
  static const synced = 'Synced';
  static const rejected = 'Rejected';
  static const offlineBanner = "You're offline. Diagnosis still works.";

  // Actions
  static const retry = 'Retry';
  static const tryAgain = 'Try again';
  static const cancel = 'Cancel';
  static const undo = 'Undo';
  static const delete = 'Delete';
  static const seeAll = 'See all';
  static const scanLeaf = 'Scan a leaf';
  static const getAdvice = 'Get advice';
  static const readOfflineNotes = 'Read offline notes';

  // Labels
  static const active = 'Active';
  static const onDevice = 'On-device';
  static const server = 'Server';
  static const potato = 'Potato';

  // Navigation
  static const navScan = 'Scan';
  static const navHistory = 'History';
  static const navSettings = 'Settings';

  /// "Model v1".
  static String model(String version) => 'Model $version';

  /// "Reference: d6720fce" (first 8 chars of a request id).
  static String reference(String requestId) {
    final short = requestId.length > 8 ? requestId.substring(0, 8) : requestId;
    return 'Reference: $short';
  }
}
