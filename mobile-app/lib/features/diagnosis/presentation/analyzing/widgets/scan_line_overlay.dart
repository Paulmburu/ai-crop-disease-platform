import 'dart:async';

import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/motion.dart';

/// A 2 dp primary line with a 24 dp tinted band above it, sweeping top →
/// bottom every 900 ms. [progress] fixes the position (golden key frames:
/// 0.05 = S2-A, 0.95 = S2-B); with reduce motion the line rests mid-photo.
class ScanLineOverlay extends StatefulWidget {
  const ScanLineOverlay({this.progress, super.key});
  final double? progress;

  @override
  State<ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.scanSweep,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.progress != null) {
      _c.value = widget.progress!;
    } else if (ReduceMotion.of(context)) {
      _c
        ..stop()
        ..value = 0.5;
    } else if (!_c.isAnimating) {
      unawaited(_c.repeat());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final y = AppMotion.standard.transform(_c.value) * box.maxHeight;
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: (y - 24).clamp(0, box.maxHeight),
                  height: (y < 24 ? y : 24).clamp(0, 24).toDouble(),
                  child: ColoredBox(color: primary.withValues(alpha: 0.12)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: (y - 1).clamp(0, box.maxHeight - 2),
                  height: 2,
                  child: ColoredBox(color: primary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
