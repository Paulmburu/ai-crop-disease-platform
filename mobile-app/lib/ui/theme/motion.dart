import 'package:flutter/material.dart';

/// Motion tokens (DESIGN.md "Motion tokens").
abstract final class AppMotion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);

  /// Delay between items in a staggered list.
  static const stagger = Duration(milliseconds: 40);

  /// Scan-button pulse period and the analyzing scan-line sweep.
  static const pulse = Duration(milliseconds: 2400);
  static const scanSweep = Duration(milliseconds: 900);
  static const skeletonPulse = Duration(milliseconds: 1200);

  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exit = Easing.emphasizedAccelerate;
  static const Curve standard = Easing.standard;
}

/// App-level "reduce motion" setting (Settings → Display). Combined with the
/// OS setting in [ReduceMotion.of].
class ReduceMotionScope extends InheritedWidget {
  const ReduceMotionScope({
    required this.enabled,
    required super.child,
    super.key,
  });

  final bool enabled;

  @override
  bool updateShouldNotify(ReduceMotionScope oldWidget) =>
      enabled != oldWidget.enabled;
}

abstract final class ReduceMotion {
  /// True when the OS or the app asks for reduced motion. Animations then
  /// show their end state immediately (or a ≤150 ms fade).
  static bool of(BuildContext context) {
    final app = context
        .dependOnInheritedWidgetOfExactType<ReduceMotionScope>()
        ?.enabled;
    return (app ?? false) || MediaQuery.disableAnimationsOf(context);
  }

  /// [d], or zero when motion is reduced.
  static Duration duration(BuildContext context, Duration d) =>
      of(context) ? Duration.zero : d;
}
