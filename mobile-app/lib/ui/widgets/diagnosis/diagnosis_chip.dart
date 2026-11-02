import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/diagnosis_tone.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// Icon in the diagnosis colour (e.g. before a list title).
class DiagnosisIcon extends StatelessWidget {
  const DiagnosisIcon(this.tone, {this.size = AppSize.chipIcon, super.key});

  final DiagnosisTone tone;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(tone.icon, size: size, color: tone.colors(context).main);
}

/// Icon + label on the diagnosis container colour. Status is never shown by
/// colour alone.
class DiagnosisChip extends StatelessWidget {
  const DiagnosisChip({
    required this.tone,
    required this.label,
    this.large = false,
    super.key,
  });

  final DiagnosisTone tone;
  final String label;

  /// Full-width header style (component sheet §5) instead of a compact chip.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final col = tone.colors(context);
    final text = Theme.of(context).textTheme;
    final row = Row(
      mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(
          tone.icon,
          size: large ? AppSize.icon : AppSize.chipIcon,
          color: col.main,
        ),
        const SizedBox(width: AppSpace.sm),
        Text(
          label,
          style: (large ? text.titleMedium : text.labelLarge)?.copyWith(
            color: col.onContainer,
          ),
        ),
      ],
    );
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        height: large ? AppSize.minTouch : AppSize.chip,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          color: col.container,
          borderRadius: BorderRadius.circular(
            large ? AppRadius.field : AppRadius.full,
          ),
        ),
        child: row,
      ),
    );
  }
}
