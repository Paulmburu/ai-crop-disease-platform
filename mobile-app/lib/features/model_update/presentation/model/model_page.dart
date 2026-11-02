import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';
import 'package:leafcheck/features/model_update/presentation/model/model_state.dart';
import 'package:leafcheck/features/model_update/presentation/model/widgets/model_cards.dart';
import 'package:leafcheck/features/model_update/presentation/strings/model_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/feedback/app_snackbar.dart';

/// S6 Diagnosis model (s6_a…e).
class ModelPage extends ConsumerWidget {
  const ModelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(modelControllerProvider);
    final ctrl = ref.read(modelControllerProvider.notifier);
    final now = ref.watch(clockProvider)();

    ref.listen(modelControllerProvider, (prev, next) {
      if (prev?.phase != ModelUpdatePhase.installed &&
          next.phase == ModelUpdatePhase.installed) {
        AppSnackbar.show(
          context,
          ModelStrings.ready(next.active.version),
          actionLabel: CommonStrings.undo,
          onAction: ctrl.rollback,
        );
      }
      if (next.offline && !(prev?.offline ?? false)) {
        AppSnackbar.show(context, ModelStrings.checkOffline);
      }
    });

    final when = Formatters.inlineDayTime(s.checkedAt, now);
    final labels = DiagnosisCondition.values
        .map(DiagnosisStrings.name)
        .join(', ');
    final candidate = s.candidate;

    final (statusIcon, statusText) = switch (s.phase) {
      ModelUpdatePhase.upToDate => (
        AppIcons.online,
        ModelStrings.upToDate(when),
      ),
      ModelUpdatePhase.available || ModelUpdatePhase.checkFailed => (
        AppIcons.online,
        ModelStrings.updateAvailable(when),
      ),
      ModelUpdatePhase.downloading => (
        AppIcons.info,
        ModelStrings.stillActive(s.active.version, candidate!.version),
      ),
      ModelUpdatePhase.installed => (
        AppIcons.online,
        ModelStrings.installedLine(s.previous?.version ?? ''),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text(ModelStrings.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.sm,
          AppSpace.screen,
          AppSpace.xl,
        ),
        children: [
          ModelInfoCard(model: s.active, labels: labels),
          const SizedBox(height: AppSpace.lg),
          switch (s.phase) {
            ModelUpdatePhase.available => UpdateAvailableCard(
              candidate: candidate!,
              onDownload: ctrl.download,
            ),
            ModelUpdatePhase.downloading => DownloadingCard(
              candidate: candidate!,
              progress: s.progress!,
              onCancel: ctrl.cancel,
            ),
            ModelUpdatePhase.checkFailed => CheckFailedCard(
              active: s.active.version,
              onRetry: ctrl.download,
            ),
            _ => const SizedBox.shrink(),
          },
          if (s.phase
              case ModelUpdatePhase.available ||
                  ModelUpdatePhase.downloading ||
                  ModelUpdatePhase.checkFailed)
            const SizedBox(height: AppSpace.lg),
          ModelStatusLine(icon: statusIcon, text: statusText),
          const SizedBox(height: AppSpace.lg),
          if (s.phase
              case ModelUpdatePhase.upToDate ||
                  ModelUpdatePhase.installed ||
                  ModelUpdatePhase.checkFailed)
            TonalButton(
              label: ModelStrings.checkForUpdates,
              icon: AppIcons.refresh,
              onPressed: s.checking ? null : ctrl.check,
            ),
          // Rollback only when there is a backup (no dead button).
          if (s.previous != null) ...[
            const SizedBox(height: AppSpace.sm),
            Center(
              child: AppTextButton(
                label: ModelStrings.goBackTo(s.previous!.version),
                onPressed: ctrl.rollback,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
