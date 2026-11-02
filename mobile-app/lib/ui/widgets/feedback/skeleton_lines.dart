import 'dart:async';

import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// Placeholder text lines that pulse in opacity (no coloured shimmer).
class SkeletonLines extends StatefulWidget {
  const SkeletonLines({
    this.widths = const [1, 0.94, 0.88, 0.52],
    super.key,
  });

  /// Width of each line as a fraction of the available width.
  final List<double> widths;

  @override
  State<SkeletonLines> createState() => _SkeletonLinesState();
}

class _SkeletonLinesState extends State<SkeletonLines>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReduceMotion.of(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      unawaited(_c.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Semantics(
      label: 'Loading',
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.5).animate(_c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final w in widget.widths)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: FractionallySizedBox(
                  widthFactor: w,
                  child: Container(
                    height: AppSpace.md,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
