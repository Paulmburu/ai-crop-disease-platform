import 'package:flutter/material.dart';

/// Colours for one diagnosis status. Always shown together with an icon and
/// a label, never alone.
@immutable
class StatusColors {
  const StatusColors({
    required this.main,
    required this.bar,
    required this.container,
    required this.onContainer,
  });

  factory StatusColors.lerp(StatusColors a, StatusColors b, double t) =>
      StatusColors(
        main: Color.lerp(a.main, b.main, t)!,
        bar: Color.lerp(a.bar, b.bar, t)!,
        container: Color.lerp(a.container, b.container, t)!,
        onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
      );

  /// Icon and text colour on the surface.
  final Color main;

  /// Confidence bar fill.
  final Color bar;
  final Color container;
  final Color onContainer;
}

/// Semantic diagnosis colours (DESIGN.md "Diagnosis colours").
@immutable
class DiagnosisColors extends ThemeExtension<DiagnosisColors> {
  const DiagnosisColors({
    required this.healthy,
    required this.earlyBlight,
    required this.lateBlight,
    required this.uncertain,
  });

  final StatusColors healthy;
  final StatusColors earlyBlight;
  final StatusColors lateBlight;
  final StatusColors uncertain;

  static const light = DiagnosisColors(
    healthy: StatusColors(
      main: Color(0xFF2E7D32),
      bar: Color(0xFF2E7D32),
      container: Color(0xFFDCEFD9),
      onContainer: Color(0xFF0B3D0F),
    ),
    earlyBlight: StatusColors(
      main: Color(0xFFB26A00),
      bar: Color(0xFFF9A825),
      container: Color(0xFFFFF0C7),
      onContainer: Color(0xFF4A3200),
    ),
    lateBlight: StatusColors(
      main: Color(0xFFB23B1E),
      bar: Color(0xFFB23B1E),
      container: Color(0xFFFCE3DC),
      onContainer: Color(0xFF5E1607),
    ),
    uncertain: StatusColors(
      main: Color(0xFF5F6B73),
      bar: Color(0xFF5F6B73),
      container: Color(0xFFE6EBEE),
      onContainer: Color(0xFF263238),
    ),
  );

  /// Dark: containers are the light text colours, text is the light
  /// containers (STITCH_PROMPTS "Dark mode variants"); mains are lightened
  /// for AA contrast on #101510.
  static const dark = DiagnosisColors(
    healthy: StatusColors(
      main: Color(0xFF9DD49A),
      bar: Color(0xFF9DD49A),
      container: Color(0xFF0B3D0F),
      onContainer: Color(0xFFDCEFD9),
    ),
    earlyBlight: StatusColors(
      main: Color(0xFFFFC95C),
      bar: Color(0xFFF9A825),
      container: Color(0xFF4A3200),
      onContainer: Color(0xFFFFF0C7),
    ),
    lateBlight: StatusColors(
      main: Color(0xFFFFB4A1),
      bar: Color(0xFFE06A4C),
      container: Color(0xFF5E1607),
      onContainer: Color(0xFFFCE3DC),
    ),
    uncertain: StatusColors(
      main: Color(0xFFB6C2C9),
      bar: Color(0xFF8E9BA3),
      container: Color(0xFF263238),
      onContainer: Color(0xFFE6EBEE),
    ),
  );

  @override
  DiagnosisColors copyWith({
    StatusColors? healthy,
    StatusColors? earlyBlight,
    StatusColors? lateBlight,
    StatusColors? uncertain,
  }) => DiagnosisColors(
    healthy: healthy ?? this.healthy,
    earlyBlight: earlyBlight ?? this.earlyBlight,
    lateBlight: lateBlight ?? this.lateBlight,
    uncertain: uncertain ?? this.uncertain,
  );

  @override
  DiagnosisColors lerp(DiagnosisColors? other, double t) {
    if (other == null) return this;
    return DiagnosisColors(
      healthy: StatusColors.lerp(healthy, other.healthy, t),
      earlyBlight: StatusColors.lerp(earlyBlight, other.earlyBlight, t),
      lateBlight: StatusColors.lerp(lateBlight, other.lateBlight, t),
      uncertain: StatusColors.lerp(uncertain, other.uncertain, t),
    );
  }
}

extension DiagnosisColorsX on BuildContext {
  DiagnosisColors get diagnosisColors =>
      Theme.of(this).extension<DiagnosisColors>()!;
}
