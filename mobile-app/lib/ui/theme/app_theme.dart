import 'package:flutter/material.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/theme/diagnosis_colors.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';

/// Light and dark `ThemeData` built only from the tokens.
abstract final class AppTheme {
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: LightTokens.primary,
    onPrimary: LightTokens.onPrimary,
    primaryContainer: LightTokens.primaryContainer,
    onPrimaryContainer: LightTokens.onPrimaryContainer,
    inversePrimary: LightTokens.inversePrimary,
    secondary: LightTokens.secondary,
    onSecondary: LightTokens.onSecondary,
    secondaryContainer: LightTokens.secondaryContainer,
    onSecondaryContainer: LightTokens.onSecondaryContainer,
    surface: LightTokens.surface,
    surfaceDim: LightTokens.surfaceDim,
    surfaceBright: LightTokens.surfaceBright,
    surfaceContainerLowest: LightTokens.surfaceContainerLowest,
    surfaceContainerLow: LightTokens.surfaceContainerLow,
    surfaceContainer: LightTokens.surfaceContainer,
    surfaceContainerHigh: LightTokens.surfaceContainerHigh,
    surfaceContainerHighest: LightTokens.surfaceContainerHighest,
    onSurface: LightTokens.onSurface,
    onSurfaceVariant: LightTokens.onSurfaceVariant,
    inverseSurface: LightTokens.inverseSurface,
    onInverseSurface: LightTokens.onInverseSurface,
    outline: LightTokens.outline,
    outlineVariant: LightTokens.outlineVariant,
    error: LightTokens.error,
    onError: LightTokens.onError,
    errorContainer: LightTokens.errorContainer,
    onErrorContainer: LightTokens.onErrorContainer,
    scrim: LightTokens.scrim,
    surfaceTint: Colors.transparent, // flat tonal surfaces, no tint
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: DarkTokens.primary,
    onPrimary: DarkTokens.onPrimary,
    primaryContainer: DarkTokens.primaryContainer,
    onPrimaryContainer: DarkTokens.onPrimaryContainer,
    inversePrimary: DarkTokens.inversePrimary,
    secondary: DarkTokens.secondary,
    onSecondary: DarkTokens.onSecondary,
    secondaryContainer: DarkTokens.secondaryContainer,
    onSecondaryContainer: DarkTokens.onSecondaryContainer,
    surface: DarkTokens.surface,
    surfaceDim: DarkTokens.surfaceDim,
    surfaceBright: DarkTokens.surfaceBright,
    surfaceContainerLowest: DarkTokens.surfaceContainerLowest,
    surfaceContainerLow: DarkTokens.surfaceContainerLow,
    surfaceContainer: DarkTokens.surfaceContainer,
    surfaceContainerHigh: DarkTokens.surfaceContainerHigh,
    surfaceContainerHighest: DarkTokens.surfaceContainerHighest,
    onSurface: DarkTokens.onSurface,
    onSurfaceVariant: DarkTokens.onSurfaceVariant,
    inverseSurface: DarkTokens.inverseSurface,
    onInverseSurface: DarkTokens.onInverseSurface,
    outline: DarkTokens.outline,
    outlineVariant: DarkTokens.outlineVariant,
    error: DarkTokens.error,
    onError: DarkTokens.onError,
    errorContainer: DarkTokens.errorContainer,
    onErrorContainer: DarkTokens.onErrorContainer,
    scrim: DarkTokens.scrim,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light =>
      _build(lightScheme, DiagnosisColors.light, LightTokens.primaryText);
  static ThemeData get dark =>
      _build(darkScheme, DiagnosisColors.dark, DarkTokens.primaryText);

  static ThemeData _build(
    ColorScheme c,
    DiagnosisColors diag,
    Color primaryText,
  ) {
    final text = AppTypography.textTheme(c.onSurface);
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: c,
      fontFamily: AppAssets.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.surface,
      extensions: [diag],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSize.primaryButton),
          shape: buttonShape,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSize.minTouch, AppSize.minTouch),
          foregroundColor: primaryText,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: buttonShape,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
        ),
        labelStyle: text.labelMedium,
        side: BorderSide(color: c.outline),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSize.navBar,
        backgroundColor: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected)
                ? c.onSurface
                : c.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: AppSize.icon,
            color: s.contains(WidgetState.selected)
                ? c.onPrimaryContainer
                : c.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        showDragHandle: true,
        dragHandleColor: c.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onInverseSurface),
        actionTextColor: c.inversePrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerHigh,
        hintStyle: text.bodyLarge?.copyWith(color: c.onSurfaceVariant),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.field)),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceContainerHigh,
        circularTrackColor: c.surfaceContainerHigh,
      ),
      switchTheme: const SwitchThemeData(),
      iconTheme: IconThemeData(color: c.onSurfaceVariant, size: AppSize.icon),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
