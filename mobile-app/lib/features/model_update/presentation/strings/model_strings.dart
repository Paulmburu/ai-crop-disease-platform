/// Copy for the Diagnosis model screen (S6).
abstract final class ModelStrings {
  static const title = 'Diagnosis model';
  static const recognises = 'Recognises';
  static const size = 'Size';
  static const threshold = 'Confidence threshold';
  static const installed = 'Installed';
  static const checksum = 'Checksum';
  static const checkForUpdates = 'Check for updates';
  static const restoreBuiltIn = 'Restore built-in model';
  static const downloadOnWifi = 'Download on Wi-Fi to save data.';
  static const keepsActive = 'stays active until';
  static const failedTitle = "Download didn't pass the safety check";
  static const checkOffline = 'Checking for updates needs internet.';

  static String goBackTo(String v) => 'Go back to $v';
  static String available(String v) => 'Model $v is available';
  static String download(String v) => 'Download $v';
  static String downloading(String v) => 'Downloading model $v';
  static String ready(String v) => 'Model $v is ready';
  static String failedBody(String active) =>
      'The file was damaged or changed, so it was deleted. Model $active is '
      'still active.';
  static String candidateInfo(String size, String date) =>
      '$size · Same three conditions · Published $date';
  static String timeLeft(String progress, int seconds) =>
      '$progress · about $seconds s left';
  static String stillActive(String active, String next) =>
      'Model $active stays active until $next is checked.';

  static String upToDate(String when) => 'Up to date · checked $when';
  static String updateAvailable(String when) =>
      'Update available · checked $when';
  static String installedLine(String previous) =>
      'Checked and installed · $previous kept as backup';
}
