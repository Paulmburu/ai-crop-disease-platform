import 'package:flutter/painting.dart';

/// Colour tokens from `designs/field_diagnostic_tool/DESIGN.md`.
///
/// Overrides (UI_IMPLEMENTATION §1): `primary` is #2E7D32 (the YAML's
/// #0d631b is a Stitch tonal adjustment the screens don't use). Dark tokens
/// come from STITCH_PROMPTS §1 because the exported DESIGN.md has none.
abstract final class LightTokens {
  static const primary = Color(0xFF2E7D32);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFB8F0B0);
  static const onPrimaryContainer = Color(0xFF002204);
  static const inversePrimary = Color(0xFF88D982);
  static const secondary = Color(0xFF52634F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFD5E8CF);
  static const onSecondaryContainer = Color(0xFF101F0F);
  static const surface = Color(0xFFF7FBF2);
  static const surfaceDim = Color(0xFFD7DBD3);
  static const surfaceBright = Color(0xFFF7FBF2);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F5EC);
  static const surfaceContainer = Color(0xFFEBEFE6);
  static const surfaceContainerHigh = Color(0xFFE6E9E1);
  static const surfaceContainerHighest = Color(0xFFE0E4DB);
  static const onSurface = Color(0xFF181D17);
  static const onSurfaceVariant = Color(0xFF424940);
  static const inverseSurface = Color(0xFF2D322C);
  static const onInverseSurface = Color(0xFFEEF2E9);
  static const outline = Color(0xFF72796F);
  static const outlineVariant = Color(0xFFC2C8BD);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const scrim = Color(0x52000000); // 32% black (sheets)

  /// Primary used as TEXT (links, text buttons). #2E7D32 is only 4.2:1 on
  /// surface-container-high; this passes WCAG AA on every light surface.
  static const primaryText = Color(0xFF1B5E20);
}

abstract final class DarkTokens {
  static const primary = Color(0xFF9DD49A);
  static const onPrimary = Color(0xFF003909);
  static const primaryContainer = Color(0xFF1B5E20);
  static const onPrimaryContainer = Color(0xFFB8F0B0);
  static const inversePrimary = Color(0xFF2E7D32);
  static const secondary = Color(0xFFB9CCB4);
  static const onSecondary = Color(0xFF253423);
  static const secondaryContainer = Color(0xFF3B4B39);
  static const onSecondaryContainer = Color(0xFFD5E8CF);
  static const surface = Color(0xFF101510);
  static const surfaceDim = Color(0xFF101510);
  static const surfaceBright = Color(0xFF353A34);
  static const surfaceContainerLowest = Color(0xFF0B0F0B);
  static const surfaceContainerLow = Color(0xFF181D17);
  static const surfaceContainer = Color(0xFF1C211B);
  static const surfaceContainerHigh = Color(0xFF262B25);
  static const surfaceContainerHighest = Color(0xFF313630);
  static const onSurface = Color(0xFFDFE4DA);
  static const onSurfaceVariant = Color(0xFFC2C8BD);
  static const inverseSurface = Color(0xFFDFE4DA);
  static const onInverseSurface = Color(0xFF2D322C);
  static const outline = Color(0xFF8C9388);
  static const outlineVariant = Color(0xFF424940);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
  static const scrim = Color(0x99000000);
  static const Color primaryText = primary;
}

/// 4 dp grid (DESIGN.md "Spacing").
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Side padding of every screen.
  static const double screen = lg;

  /// Gap between cards.
  static const double cardGap = md;

  /// Gap between sections.
  static const double section = xl;
}

/// Corner radii (DESIGN.md "Spacing, shape, elevation").
abstract final class AppRadius {
  static const xs = 4.0;
  static const chip = 8.0;
  static const field = 12.0;
  static const thumbnail = 12.0;
  static const card = 16.0;
  static const button = 16.0;
  static const sheet = 28.0;
  static const full = 999.0;
}

/// Fixed component sizes (DESIGN.md "Components").
abstract final class AppSize {
  static const minTouch = 48.0;
  static const primaryButton = 56.0;
  static const tonalButton = 48.0;
  static const chip = 32.0;
  static const chipIcon = 20.0;
  static const icon = 24.0;
  static const navBar = 80.0;
  static const listTile = 72.0;
  static const thumbnail = 56.0;
  static const confidenceBar = 8.0;
  static const smallBar = 4.0;
  static const banner = 40.0;
  static const emptyIcon = 64.0;
  static const progressRing = 48.0;
}
