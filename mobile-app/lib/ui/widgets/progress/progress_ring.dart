import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// 48 dp determinate ring that morphs into a check mark at 100%.
class ProgressRing extends StatelessWidget {
  const ProgressRing({required this.value, super.key});

  /// 0–1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final done = value >= 1;
    return SizedBox.square(
      dimension: AppSize.progressRing,
      child: AnimatedSwitcher(
        duration: ReduceMotion.duration(context, AppMotion.medium),
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: done
            ? Icon(
                AppIcons.check,
                key: const ValueKey('done'),
                size: AppSize.progressRing,
                color: c.primary,
              )
            : CircularProgressIndicator(
                key: const ValueKey('progress'),
                value: value,
                strokeWidth: 4,
              ),
      ),
    );
  }
}
