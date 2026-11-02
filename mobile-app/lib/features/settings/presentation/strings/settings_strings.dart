/// Copy for Settings, Diagnostics and Speed test (S7).
abstract final class SettingsStrings {
  static const title = 'Settings';
  static const sectionDiagnosis = 'Diagnosis';
  static const sectionServer = 'Server';
  static const sectionDisplay = 'Display';
  static const sectionAbout = 'About';
  static const sectionDebug = 'Debug';
  static const diagnosisModel = 'Diagnosis model';
  static const serverAddress = 'Server address';
  static const accessKey = 'Access key';
  static const keySet = '•••••••• set';
  static const keyMissing = 'Not set';
  static const diagnostics = 'Diagnostics';
  static const allWorking = 'All services working';
  static const offline = 'Offline';
  static const theme = 'Theme';
  static const light = 'Light';
  static const dark = 'Dark';
  static const system = 'System';
  static const reduceMotion = 'Reduce motion';
  static const deviceId = 'Device ID';
  static const version = 'Version';
  static const appVersion = '1.0.0 (1)';
  static const mockScenario = 'Mock scenario';
  static const restartToApply =
      'Restart the app with this scenario: '
      'flutter run --dart-define=SCENARIO=';
  static const androidEmulator = 'Android emulator';

  static String modelSummary(String v, {required bool upToDate}) =>
      upToDate ? '$v · up to date' : v;
  static String issues(int n) => n == 1 ? '1 issue' : '$n issues';

  // Diagnostics
  static const services = 'Services';
  static const server = 'Server';
  static const database = 'Database';
  static const diagnosisService = 'Diagnosis service';
  static const adviceService = 'Advice service';
  static const ok = 'OK';
  static const down = 'Down';
  static const sync = 'Sync';
  static const waitingToSync = 'Waiting to sync';
  static const lastSync = 'Last sync';
  static const syncedTotal = 'Synced in total';
  static const thisPhone = 'This phone';
  static const model = 'Model';
  static const inferenceLast = 'Inference (last)';
  static const phone = 'Phone';
  static const phoneName = 'Pixel 7a · Android 16'; // mock device info
  static const refresh = 'Refresh';
  static const runSpeedTest = 'Run speed test';
  static String okMs(int ms) => 'OK · $ms ms';
  static String checked(String time, String url) => 'Checked $time · $url';

  // Speed test
  static const speedTitle = 'Speed test';
  static String speedIntro(int runs) =>
      '$runs diagnoses of the same photo on this phone, no internet.';
  static const typical = 'Typical (p50)';
  static const slow = 'Slow (p95)';
  static const ms = 'ms';
  static const compared = 'Compared with the server';
  static const serverWifi = 'Server over Wi-Fi';
  static const server3g = 'Server over 3G';
  static const wifiValue = '≈ 1.3 s';
  static const g3Value = '≈ 34 s';
  static const estimateNote =
      'Server times include uploading a 3 MB photo (estimated).';
  static const runAgain = 'Run again';
  static const start = 'Start';
  static String running(int done, int total) => 'Run $done of $total';
}
