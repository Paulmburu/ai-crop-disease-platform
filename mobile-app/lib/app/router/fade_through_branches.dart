import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/motion.dart';

/// Keeps every tab alive (like IndexedStack) and fades the selected tab in
/// (Material fade-through, 300 ms). Instant with reduce motion.
class FadeThroughBranches extends StatelessWidget {
  const FadeThroughBranches({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (var i = 0; i < children.length; i++)
        Offstage(
          offstage: i != index,
          child: TickerMode(
            enabled: i == index,
            child: i == index
                ? TweenAnimationBuilder<double>(
                    key: ValueKey('tab-$index'),
                    tween: Tween(begin: 0, end: 1),
                    duration: ReduceMotion.duration(context, AppMotion.medium),
                    curve: AppMotion.enter,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.scale(
                        scale: 0.92 + 0.08 * v,
                        child: child,
                      ),
                    ),
                    child: children[i],
                  )
                : children[i],
          ),
        ),
    ],
  );
}
