import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// 8 dp bar filled to [value] (0–1) with a tick at [threshold]. Animates from
/// 0 on first build (500 ms, emphasized decelerate) unless motion is reduced.
class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({
    required this.value,
    required this.color,
    this.threshold,
    this.height = AppSize.confidenceBar,
    super.key,
  });

  final double value;
  final double? threshold;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: ReduceMotion.duration(context, AppMotion.long),
      curve: AppMotion.enter,
      builder: (context, v, _) => LayoutBuilder(
        builder: (context, box) => SizedBox(
          height: height + 6, // room for the threshold tick
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              _bar(box.maxWidth, c.surfaceContainerHigh),
              _bar(box.maxWidth * v, color),
              if (threshold != null)
                Positioned(
                  left: box.maxWidth * threshold! - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: c.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(double width, Color color) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
  );
}

/// A number that counts up to [value] with the same timing as the bar.
class CountUpText extends StatelessWidget {
  const CountUpText({
    required this.value,
    required this.format,
    this.style,
    super.key,
  });

  final double value;
  final String Function(double) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: ReduceMotion.duration(context, AppMotion.long),
    curve: AppMotion.enter,
    builder: (_, v, _) => Text(format(v), style: style),
  );
}
