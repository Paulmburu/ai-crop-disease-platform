import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/features/advice/presentation/advice_sheet/advice_state.dart';
import 'package:leafcheck/features/advice/presentation/advice_sheet/widgets/advice_answer.dart';
import 'package:leafcheck/features/advice/presentation/advice_sheet/widgets/advice_parts.dart';
import 'package:leafcheck/features/advice/presentation/strings/advice_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/diagnosis_tone.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/feedback/app_snackbar.dart';
import 'package:leafcheck/ui/widgets/feedback/empty_state.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// S4 Advice (s4_a…e) as a modal sheet over Result.
class AdviceSheet extends ConsumerWidget {
  const AdviceSheet({
    required this.classLabel,
    required this.conditionName,
    required this.tone,
    super.key,
  });

  /// Model label sent to the server, e.g. `Potato___Late_blight`.
  final String classLabel;
  final String conditionName;
  final DiagnosisTone tone;

  static Future<void> show(
    BuildContext context, {
    required String classLabel,
    required String conditionName,
    required DiagnosisTone tone,
  }) => AppBottomSheet.show<void>(
    context,
    expand: true,
    builder: (_) => AdviceSheet(
      classLabel: classLabel,
      conditionName: conditionName,
      tone: tone,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adviceControllerProvider(classLabel));
    final ctrl = ref.read(adviceControllerProvider(classLabel).notifier);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final phase = state.phase;
    final showInput = switch (phase) {
      AdvicePhase.offline || AdvicePhase.unavailable => false,
      _ => true,
    };

    final body = switch (phase) {
      AdvicePhase.questions || AdvicePhase.invalid => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AdviceStrings.title(conditionName), style: t.headlineSmall),
          const SizedBox(height: AppSpace.xs),
          Text(
            AdviceStrings.subtitle,
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          if (phase == AdvicePhase.invalid) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              AdviceStrings.tooShort,
              style: t.bodyMedium?.copyWith(color: c.error),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          SuggestedQuestions(onAsk: ctrl.ask),
        ],
      ),
      AdvicePhase.loading => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionBubble(state.question!),
          const SizedBox(height: AppSpace.xl),
          const AdviceLoading(),
        ],
      ),
      AdvicePhase.answer => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionBubble(state.question!),
          const SizedBox(height: AppSpace.xl),
          AdviceAnswerView(state.answer!),
        ],
      ),
      AdvicePhase.offline => EmptyState(
        icon: AppIcons.offline,
        title: AdviceStrings.offlineTitle,
        message: AdviceStrings.offlineBody,
        actions: [
          TonalButton(
            label: AdviceStrings.askWhenOnline,
            icon: AppIcons.pending,
            onPressed: () {
              // ponytail: the queued question is not persisted yet (F3).
              AppSnackbar.show(context, AdviceStrings.queued);
              Navigator.pop(context);
            },
          ),
          _offlineNotes(context),
        ],
      ),
      AdvicePhase.unavailable => EmptyState(
        icon: AppIcons.build,
        title: AdviceStrings.unavailableTitle,
        message: AdviceStrings.unavailableBody,
        footer: state.requestId == null
            ? null
            : CommonStrings.reference(state.requestId!),
        actions: [
          TonalButton(
            label: CommonStrings.tryAgain,
            icon: AppIcons.refresh,
            onPressed: () => state.question == null
                ? ctrl.reset()
                : ctrl.ask(state.question!),
          ),
          _offlineNotes(context),
        ],
      ),
    };

    final centered =
        phase == AdvicePhase.offline || phase == AdvicePhase.unavailable;
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: SheetHeader(tone: tone, label: conditionName),
            ),
            Expanded(
              child: centered
                  ? Center(child: SingleChildScrollView(child: body))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.sm,
                        AppSpace.lg,
                        AppSpace.lg,
                      ),
                      child: body,
                    ),
            ),
            if (showInput)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    0,
                    AppSpace.lg,
                    AppSpace.md,
                  ),
                  child: AdviceInput(
                    enabled: phase != AdvicePhase.loading,
                    followUp: phase == AdvicePhase.answer,
                    onSend: ctrl.ask,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Opens the bundled note for this condition (works offline).
  Widget _offlineNotes(BuildContext context) => AppTextButton(
    label: CommonStrings.readOfflineNotes,
    onPressed: () {
      final router = GoRouter.of(context); // before the sheet's context goes
      Navigator.pop(context);
      unawaited(router.push(Routes.disease(classLabel)));
    },
  );
}
