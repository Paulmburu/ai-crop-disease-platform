import 'package:flutter/material.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_presenter.dart';
import 'package:leafcheck/ui/theme/diagnosis_tone.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';
import 'package:leafcheck/ui/widgets/diagnosis/confidence_bar.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// Top-1 confidence vs threshold, then the other classes (S3).
class ConfidenceCard extends StatelessWidget {
  const ConfidenceCard(this.diagnosis, {super.key});
  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final p = diagnosis.prediction;
    final threshold = Formatters.percentWhole(p.threshold);
    final pct = Formatters.percent(diagnosis.confidence);
    final heading = diagnosis.isUncertain
        ? DiagnosisStrings.bestGuess
        : DiagnosisStrings.confidence;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '$heading $pct',
            excludeSemantics: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(heading, style: t.titleMedium),
                ),
                CountUpText(
                  value: diagnosis.confidence * 100,
                  format: (v) => '${v.toStringAsFixed(1)}%',
                  style: t.titleMedium.numeric,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          ConfidenceBar(
            value: diagnosis.confidence,
            threshold: p.threshold,
            color: diagnosis.tone.colors(context).bar,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            diagnosis.isUncertain
                ? DiagnosisStrings.belowThreshold(threshold)
                : DiagnosisStrings.aboveThreshold(threshold),
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(),
          const SizedBox(height: AppSpace.sm),
          // Uncertain lists every class (the top one is only a guess).
          for (final s in diagnosis.isUncertain ? p.scores : p.scores.skip(1))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Column(
                children: [
                  InfoRow(
                    label: DiagnosisStrings.name(s.condition),
                    value: Formatters.percent(s.probability),
                  ),
                  ConfidenceBar(
                    value: s.probability,
                    color: c.outline,
                    height: AppSize.smallBar,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
