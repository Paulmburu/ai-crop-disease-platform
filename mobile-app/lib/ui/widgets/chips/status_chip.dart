import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/diagnosis_colors.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

enum ChipTone { neutral, positive, warning, error }

/// 32 dp status chip: 20 dp icon (or spinner) + label. Not tappable.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    this.busy = false,
    super.key,
  });

  final String label;
  final ChipTone tone;
  final IconData? icon;

  /// Shows a small spinner instead of the icon (e.g. "Syncing").
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final warn = context.diagnosisColors.earlyBlight;
    final (bg, fg, border) = switch (tone) {
      ChipTone.neutral => (c.surface, c.onSurface, c.outline),
      ChipTone.positive => (c.primaryContainer, c.onPrimaryContainer, null),
      ChipTone.warning => (warn.container, warn.onContainer, null),
      ChipTone.error => (c.errorContainer, c.onErrorContainer, null),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: ReduceMotion.duration(context, AppMotion.medium),
        height: AppSize.chip,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            else if (icon != null)
              Icon(icon, size: AppSize.chipIcon, color: fg),
            if (busy || icon != null) const SizedBox(width: AppSpace.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
