import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/features/advice/presentation/advice_sheet/advice_sheet.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/result/result_state.dart';
import 'package:leafcheck/features/diagnosis/presentation/result/widgets/confidence_card.dart';
import 'package:leafcheck/features/diagnosis/presentation/result/widgets/result_actions.dart';
import 'package:leafcheck/features/diagnosis/presentation/result/widgets/result_cards.dart';
import 'package:leafcheck/features/diagnosis/presentation/result/widgets/result_header.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_presenter.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';
import 'package:leafcheck/ui/widgets/feedback/app_snackbar.dart';
import 'package:leafcheck/ui/widgets/feedback/banners.dart';

/// S3 Result (s3_a…e) and the rejected-sync variant (s5_d).
class ResultPage extends ConsumerWidget {
  const ResultPage({required this.id, super.key});

  final String id;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(DiagnosisStrings.deleteTitle),
        content: const Text(DiagnosisStrings.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(CommonStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(CommonStrings.delete),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
      await deleteDiagnosis(ref, id);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _secondOpinion(
    BuildContext context,
    WidgetRef ref,
    Diagnosis d,
  ) async {
    final failure = await ref
        .read(secondOpinionControllerProvider(id).notifier)
        .request(d);
    if (failure != null && context.mounted) {
      AppSnackbar.show(
        context,
        switch (failure) {
          Offline() => DiagnosisStrings.secondOpinionOffline,
          _ => DiagnosisStrings.analyzeFailed,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(resultProvider(id)).value;
    final loading = ref.watch(secondOpinionControllerProvider(id)).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: const Text(DiagnosisStrings.resultTitle),
        actions: [
          if (d != null)
            IconButton(
              tooltip: CommonStrings.delete,
              icon: const Icon(AppIcons.delete),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: d == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                0,
                AppSpace.screen,
                AppSpace.lg,
              ),
              children: [
                if (d.syncState == SyncState.rejected) ...[
                  ErrorBanner(
                    title: DiagnosisStrings.syncRejectedTitle,
                    message: d.rejectReason ?? '',
                    action: AppTextButton(
                      label: CommonStrings.tryAgain,
                      onPressed: () => ref.read(syncDiagnosesProvider)(),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],
                LeafPhoto(
                  image: AppAssets.photo(d.imagePath),
                  heroTag: LeafPhoto.scanHeroTag,
                  height: d.secondOpinion == null ? 240 : 120,
                  width: double.infinity,
                  semanticLabel: d.title,
                ),
                const SizedBox(height: AppSpace.lg),
                ResultHeader(d),
                const SizedBox(height: AppSpace.lg),
                ConfidenceCard(d),
                if (d.secondOpinion != null) ...[
                  const SizedBox(height: AppSpace.cardGap),
                  SecondOpinionCard(d),
                ],
                if (d.isUncertain) ...[
                  const SizedBox(height: AppSpace.cardGap),
                  const RetakeTipsCard(),
                ],
                const SizedBox(height: AppSpace.lg),
                MetaRow(d.prediction),
                if (!d.isUncertain) ...[
                  const SizedBox(height: AppSpace.lg),
                  MeaningCard(d),
                ],
              ],
            ),
      bottomNavigationBar: d == null
          ? null
          : ResultActions(
              uncertain: d.isUncertain,
              onPrimary: d.isUncertain
                  ? () => context.go(Routes.scan)
                  : () => AdviceSheet.show(
                      context,
                      classLabel: d.condition.label,
                      conditionName: d.title,
                      tone: d.tone,
                    ),
              onSecondOpinion: d.secondOpinion == null
                  ? () => _secondOpinion(context, ref, d)
                  : null,
              secondOpinionLoading: loading,
            ),
    );
  }
}
