import 'package:flutter/material.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_presenter.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';

/// Chip + large title + "Potato · pathogen" (or the "not sure" explanation).
class ResultHeader extends StatelessWidget {
  const ResultHeader(this.diagnosis, {super.key});
  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final sub = t.bodyLarge?.copyWith(color: c.onSurfaceVariant);
    final d = diagnosis;
    final Widget subtitle;
    if (d.isUncertain) {
      subtitle = Text(DiagnosisStrings.notSureBody, style: sub);
    } else if (d.condition == DiagnosisCondition.healthy) {
      subtitle = Text(DiagnosisStrings.potatoNoDisease, style: sub);
    } else {
      subtitle = Text.rich(
        TextSpan(
          style: sub,
          children: [
            const TextSpan(text: '${CommonStrings.potato} · '),
            TextSpan(
              text: DiagnosisStrings.pathogen(d.condition),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: ReduceMotion.duration(context, AppMotion.medium),
      curve: AppMotion.enter,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - v)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiagnosisChip(tone: d.tone, label: d.title),
          const SizedBox(height: AppSpace.sm),
          Semantics(
            header: true,
            child: Text(d.title, style: t.displaySmall),
          ),
          const SizedBox(height: AppSpace.xs),
          subtitle,
        ],
      ),
    );
  }
}
