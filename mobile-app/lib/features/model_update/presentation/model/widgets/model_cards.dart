import 'package:flutter/material.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';
import 'package:leafcheck/features/model_update/presentation/strings/model_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/chips/status_chip.dart';
import 'package:leafcheck/ui/widgets/feedback/banners.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';
import 'package:leafcheck/ui/widgets/progress/progress_ring.dart';

/// Active model with its facts (S6-A/D).
class ModelInfoCard extends StatelessWidget {
  const ModelInfoCard({required this.model, required this.labels, super.key});

  final ModelRelease model;

  /// "Early blight, Late blight, Healthy" (display names from the feature).
  final String labels;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget row(String l, String v) => Column(
      children: [
        const Divider(),
        InfoRow(label: l, value: v),
      ],
    );
    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: c.primaryContainer,
                child: Icon(AppIcons.model, color: c.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  CommonStrings.model(model.version),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const StatusChip(
                label: CommonStrings.active,
                tone: ChipTone.positive,
                icon: AppIcons.check,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          row(ModelStrings.recognises, labels),
          row(ModelStrings.size, Formatters.megabytes(model.sizeBytes)),
          row(ModelStrings.threshold, Formatters.percentWhole(model.threshold)),
          row(ModelStrings.installed, Formatters.date(model.date)),
          row(ModelStrings.checksum, Formatters.shortSha(model.sha256)),
        ],
      ),
    );
  }
}

/// Icon + one line under the card ("Up to date · checked today 10:20").
class ModelStatusLine extends StatelessWidget {
  const ModelStatusLine({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: c.primary),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

/// Primary-container card offering the new version (S6-B).
class UpdateAvailableCard extends StatelessWidget {
  const UpdateAvailableCard({
    required this.candidate,
    required this.onDownload,
    super.key,
  });

  final ModelRelease candidate;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final on = c.onSecondaryContainer;
    return SectionCard(
      color: c.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.download, color: on),
              const SizedBox(width: AppSpace.sm),
              Text(
                ModelStrings.available(candidate.version),
                style: t.titleMedium?.copyWith(color: on),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            ModelStrings.candidateInfo(
              Formatters.megabytes(candidate.sizeBytes),
              Formatters.date(candidate.date),
            ),
            style: t.bodyMedium?.copyWith(color: on),
          ),
          Text(
            ModelStrings.downloadOnWifi,
            style: t.bodyMedium?.copyWith(color: on),
          ),
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(
            label: ModelStrings.download(candidate.version),
            icon: AppIcons.download,
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }
}

/// Ring + percent + bytes; the ring becomes a check at 100 % (S6-C → D).
class DownloadingCard extends StatelessWidget {
  const DownloadingCard({
    required this.candidate,
    required this.progress,
    required this.onCancel,
    super.key,
  });

  final ModelRelease candidate;
  final DownloadProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    // ponytail: fixed ETA curve; real one from measured throughput (F4).
    final secondsLeft = (35 * (1 - progress.fraction)).round();
    return SectionCard(
      color: c.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ModelStrings.downloading(candidate.version),
                  style: t.titleMedium?.copyWith(
                    color: c.onSecondaryContainer,
                  ),
                ),
              ),
              if (!progress.done)
                AppTextButton(label: CommonStrings.cancel, onPressed: onCancel),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              ProgressRing(value: progress.fraction),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(progress.fraction * 100).round()}%',
                      style: t.titleMedium.numeric,
                    ),
                    Text(
                      ModelStrings.timeLeft(
                        Formatters.megabytesOf(
                          progress.received,
                          progress.total,
                        ),
                        secondsLeft,
                      ),
                      style: t.bodyMedium.numeric,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// S6-E: the downloaded file failed the sha256 check.
class CheckFailedCard extends StatelessWidget {
  const CheckFailedCard({
    required this.active,
    required this.onRetry,
    super.key,
  });

  final String active;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ErrorBanner(
    icon: AppIcons.shieldFail,
    title: ModelStrings.failedTitle,
    message: ModelStrings.failedBody(active),
    action: AppTextButton(label: CommonStrings.tryAgain, onPressed: onRetry),
  );
}
