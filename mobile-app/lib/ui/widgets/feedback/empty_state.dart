import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// Centred icon + title + message + optional actions. No illustrations.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
    this.footer,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  /// Small caption under the actions (e.g. "Reference: d6720fce").
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: ReduceMotion.duration(context, AppMotion.medium),
      builder: (_, o, child) => Opacity(opacity: o, child: child),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSize.emptyIcon, color: c.onSurfaceVariant),
            const SizedBox(height: AppSpace.lg),
            Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.sm),
            Text(
              message,
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            for (final a in actions) ...[
              const SizedBox(height: AppSpace.md),
              a,
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                footer!,
                style: t.labelMedium?.copyWith(color: c.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
