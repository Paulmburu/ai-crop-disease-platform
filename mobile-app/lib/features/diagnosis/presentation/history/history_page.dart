import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/presentation/history/history_state.dart';
import 'package:leafcheck/features/diagnosis/presentation/history/widgets/day_section.dart';
import 'package:leafcheck/features/diagnosis/presentation/history/widgets/sync_summary_row.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/feedback/app_snackbar.dart';
import 'package:leafcheck/ui/widgets/feedback/empty_state.dart';

/// S5 History (s5_a list, S5-B syncing, s5_c empty).
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final r = await syncNow(ref);
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      switch (r) {
        Ok(:final value) => DiagnosisStrings.syncedCount(value),
        Err() => DiagnosisStrings.syncOffline,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyStateProvider).value;
    final now = ref.watch(clockProvider)();
    final empty = state?.isEmpty ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(DiagnosisStrings.historyTitle),
        actions: [
          if (!empty)
            IconButton(
              tooltip: DiagnosisStrings.syncNow,
              icon: const Icon(AppIcons.sync),
              onPressed: state?.syncing ?? false
                  ? null
                  : () => _sync(context, ref),
            ),
        ],
      ),
      body: switch (state) {
        null => const SizedBox.shrink(),
        _ when empty => Center(
          child: EmptyState(
            icon: AppIcons.history,
            title: DiagnosisStrings.emptyTitle,
            message: DiagnosisStrings.emptyBody,
            actions: [
              TonalButton(
                label: CommonStrings.scanLeaf,
                icon: AppIcons.camera,
                expand: false,
                onPressed: () => context.go(Routes.scan),
              ),
            ],
          ),
        ),
        final s => RefreshIndicator(
          onRefresh: () => _sync(context, ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              0,
              AppSpace.screen,
              AppSpace.xl,
            ),
            children: [
              SyncSummaryRow(
                s.syncing
                    ? DiagnosisStrings.syncingCount(s.syncingCount)
                    : DiagnosisStrings.syncSummary(
                        s.pending,
                        lastSyncLabel(s.lastSync, now),
                      ),
              ),
              for (final day in s.days)
                DaySectionView(
                  section: day,
                  now: now,
                  onOpen: (d) => context.push(Routes.diagnosis(d.id)),
                ),
            ],
          ),
        ),
      },
    );
  }
}
