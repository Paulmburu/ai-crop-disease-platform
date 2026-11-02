import 'package:flutter/material.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';

/// Type scale from the DESIGN.md YAML (size / line height / weight /
/// letter-spacing). `height` is line height ÷ font size.
abstract final class AppTypography {
  static TextStyle _s(
    double size,
    double line,
    FontWeight w, [
    double ls = 0,
  ]) => TextStyle(
    fontFamily: AppAssets.fontFamily,
    fontSize: size,
    height: line / size,
    fontWeight: w,
    letterSpacing: ls,
  );

  static const FontWeight _regular = FontWeight.w400;
  static const FontWeight _medium = FontWeight.w500;
  static const FontWeight _semi = FontWeight.w600;

  /// Result title ("Late blight"), not in the YAML: DESIGN.md prose 36/44.
  static final TextStyle displaySmall = _s(36, 44, _semi);

  static TextTheme textTheme(Color onSurface) => TextTheme(
    displaySmall: displaySmall,
    headlineLarge: _s(32, 40, _semi),
    headlineMedium: _s(28, 36, _semi),
    headlineSmall: _s(24, 32, _semi),
    titleLarge: _s(22, 28, _semi),
    titleMedium: _s(16, 24, _semi, 0.15),
    titleSmall: _s(14, 20, _semi, 0.1),
    bodyLarge: _s(16, 24, _regular, 0.5),
    bodyMedium: _s(14, 20, _regular, 0.25),
    bodySmall: _s(12, 16, _regular, 0.4),
    labelLarge: _s(14, 20, _medium, 0.1),
    labelMedium: _s(12, 16, _medium, 0.5),
    labelSmall: _s(11, 16, _medium, 0.5),
  ).apply(bodyColor: onSurface, displayColor: onSurface);
}

/// Tabular figures for numbers that change (%, ms, MB, counts).
extension NumericText on TextStyle? {
  TextStyle get numeric => (this ?? const TextStyle()).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
