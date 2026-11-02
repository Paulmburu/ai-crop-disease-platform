/// Debug-only scenarios that drive the mock adapters, so every design state
/// can be reached on the emulator (UI_IMPLEMENTATION §4).
enum MockScenario {
  online,
  offline,
  firstRun,
  uncertainPhoto,
  adviceDown,
  updateAvailable,
  checksumFail,
  syncRejected,

  /// First launch: onboarding before Scan (S8).
  onboarding
  ;

  /// Reads `--dart-define=SCENARIO=<name>`; unknown or empty → [online].
  static MockScenario fromName(String? name) => MockScenario.values.firstWhere(
    (s) => s.name == name,
    orElse: () => MockScenario.online,
  );

  static MockScenario get fromEnvironment =>
      fromName(const String.fromEnvironment('SCENARIO'));
}
