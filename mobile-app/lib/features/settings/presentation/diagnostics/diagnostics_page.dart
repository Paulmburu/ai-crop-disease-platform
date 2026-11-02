import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/history_providers.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';
import 'package:leafcheck/features/settings/presentation/diagnostics/widgets/service_row.dart';
import 'package:leafcheck/features/settings/presentation/shared/backend_status_provider.dart';
import 'package:leafcheck/features/settings/presentation/strings/settings_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// S7-B Diagnostics (s7_b_diagnostics_2).
class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  static String _name(ServiceName n) => switch (n) {
    ServiceName.server => SettingsStrings.server,
    ServiceName.database => SettingsStrings.database,
    ServiceName.diagnosis => SettingsStrings.diagnosisService,
    ServiceName.advice => SettingsStrings.adviceService,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backendStatusProvider).value;
    final all = ref.watch(historyProvider).value ?? const [];
    final sync = ref.watch(syncServiceProvider);
    final model = ref.watch(activeModelProvider);
    final settings = ref.watch(settingsRepositoryProvider).load();
    final now = ref.watch(clockProvider)();
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    Widget card(String title, List<Widget> rows) => SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleMedium),
          const SizedBox(height: AppSpace.sm),
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const Divider(),
            r,
          ],
        ],
      ),
    );

    final lastMs = all.isEmpty ? null : all.first.prediction.latencyMs;
    int count(SyncState s) => all.where((d) => d.syncState == s).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text(SettingsStrings.diagnostics),
        actions: [
          IconButton(
            tooltip: SettingsStrings.refresh,
            icon: const Icon(AppIcons.refresh),
            onPressed: () => ref.read(watchBackendStatusProvider).refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.sm,
          AppSpace.screen,
          AppSpace.xl,
        ),
        children: [
          card(SettingsStrings.services, [
            if (status == null || !status.online)
              const ServiceRow(
                name: SettingsStrings.server,
                value: CommonStrings.offline,
                ok: false,
              )
            else
              for (final s in status.services)
                ServiceRow(
                  name: _name(s.name),
                  value: !s.ok
                      ? SettingsStrings.down
                      : s.latencyMs == null
                      ? SettingsStrings.ok
                      : SettingsStrings.okMs(s.latencyMs!),
                  ok: s.ok,
                ),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: Text(
                  SettingsStrings.checked(
                    Formatters.time(status.checkedAt),
                    settings.serverUrl,
                  ),
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ),
          ]),
          const SizedBox(height: AppSpace.cardGap),
          card(SettingsStrings.sync, [
            InfoRow(
              label: SettingsStrings.waitingToSync,
              value: '${count(SyncState.pending)}',
            ),
            InfoRow(
              label: SettingsStrings.lastSync,
              value: sync.lastSyncAt == null
                  ? '—'
                  : Formatters.relativeDayTime(sync.lastSyncAt!, now),
            ),
            InfoRow(
              label: SettingsStrings.syncedTotal,
              value: '${count(SyncState.synced)}',
            ),
          ]),
          const SizedBox(height: AppSpace.cardGap),
          card(SettingsStrings.thisPhone, [
            InfoRow(
              label: SettingsStrings.model,
              value:
                  '${model.version} · ${Formatters.megabytes(model.sizeBytes)}',
            ),
            InfoRow(
              label: SettingsStrings.inferenceLast,
              value: lastMs == null ? '—' : Formatters.millis(lastMs),
            ),
            const InfoRow(
              label: SettingsStrings.phone,
              value: SettingsStrings.phoneName,
            ),
          ]),
          const SizedBox(height: AppSpace.xl),
          TonalButton(
            label: SettingsStrings.runSpeedTest,
            icon: AppIcons.speed,
            onPressed: () => context.push(Routes.speedTest),
          ),
        ],
      ),
    );
  }
}
