import 'package:flutter/material.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_presenter.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';
import 'package:leafcheck/ui/widgets/chips/status_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// "On-device · 1.9 ms · Model v1".
class MetaRow extends StatelessWidget {
  const MetaRow(this.prediction, {super.key});
  final Prediction prediction;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(AppIcons.model, size: 16, color: c.onSurfaceVariant),
        const SizedBox(width: AppSpace.sm),
        Text(
          DiagnosisStrings.meta(
            CommonStrings.onDevice,
            Formatters.millis(prediction.latencyMs),
            CommonStrings.model(prediction.modelVersion),
          ),
          style: Theme.of(context).textTheme.bodyMedium.numeric.copyWith(
            color: c.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "What this means" (confident results only).
class MeaningCard extends StatelessWidget {
  const MeaningCard(this.diagnosis, {super.key});
  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DiagnosisStrings.meaningTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          DiagnosisStrings.meaning(diagnosis.condition),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// S3-D: what to change before retaking.
class RetakeTipsCard extends StatelessWidget {
  const RetakeTipsCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DiagnosisStrings.tryAgainWith,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.xs),
        const IconTextRow(
          icon: AppIcons.sun,
          text: DiagnosisStrings.retakeDaylight,
        ),
        const IconTextRow(
          icon: AppIcons.leaf,
          text: DiagnosisStrings.retakeOneLeaf,
        ),
        const IconTextRow(
          icon: AppIcons.focus,
          text: DiagnosisStrings.retakeSharp,
        ),
      ],
    ),
  );
}

/// S3-E: phone vs server, side by side. Values stack vertically so long
/// names never wrap mid-word (fixes the Stitch layout).
class SecondOpinionCard extends StatelessWidget {
  const SecondOpinionCard(this.diagnosis, {super.key});
  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final server = diagnosis.secondOpinion!;
    final agree = server.top.condition == diagnosis.condition;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DiagnosisStrings.secondOpinion,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.md),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Side(
                    caption: DiagnosisStrings.thisPhone,
                    prediction: diagnosis.prediction,
                    latency: Formatters.millis(diagnosis.prediction.latencyMs),
                  ),
                ),
                const VerticalDivider(width: AppSpace.xl),
                Expanded(
                  child: _Side(
                    caption: CommonStrings.server,
                    prediction: server,
                    latency: DiagnosisStrings.serverLatency(
                      '${server.latencyMs.round()} ms',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(),
          const SizedBox(height: AppSpace.md),
          StatusChip(
            label: agree
                ? DiagnosisStrings.bothAgree
                : DiagnosisStrings.disagree,
            tone: agree ? ChipTone.positive : ChipTone.warning,
            icon: agree ? AppIcons.check : AppIcons.uncertain,
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.caption,
    required this.prediction,
    required this.latency,
  });

  final String caption;
  final Prediction prediction;
  final String latency;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final cond = prediction.top.condition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: t.labelMedium?.copyWith(color: c.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            DiagnosisIcon(cond.tone),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: Text(DiagnosisStrings.name(cond), style: t.titleMedium),
            ),
          ],
        ),
        Text(
          Formatters.percent(prediction.top.probability),
          style: t.titleMedium.numeric,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          latency,
          style: t.bodyMedium.numeric.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}
