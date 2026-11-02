import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/core/constants/app_constants.dart';
import 'package:leafcheck/features/settings/presentation/speed_test/speed_test_state.dart';
import 'package:leafcheck/features/settings/presentation/strings/settings_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/diagnosis/confidence_bar.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// S7-C Speed test (s7_c_speed_test), without the design's avatar.
class SpeedTestPage extends ConsumerWidget {
  const SpeedTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(speedTestProvider);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    const runs = AppConstants.speedTestRuns;

    Widget stat(String caption, double? ms) => Expanded(
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              style: t.labelMedium?.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (ms == null)
                  Text('—', style: t.displaySmall)
                else
                  CountUpText(
                    value: ms,
                    format: (v) => v.toStringAsFixed(1),
                    style: t.displaySmall.numeric,
                  ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  SettingsStrings.ms,
                  style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(SettingsStrings.speedTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.sm,
          AppSpace.screen,
          AppSpace.xl,
        ),
        children: [
          Text(
            SettingsStrings.speedIntro(runs),
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.lg),
          if (s.running) ...[
            Text(
              SettingsStrings.running(s.done, runs),
              style: t.bodyMedium.numeric,
            ),
            const SizedBox(height: AppSpace.sm),
            LinearProgressIndicator(value: s.done / runs),
            const SizedBox(height: AppSpace.lg),
          ],
          Row(
            children: [
              stat(SettingsStrings.typical, s.result?.p50Ms),
              const SizedBox(width: AppSpace.cardGap),
              stat(SettingsStrings.slow, s.result?.p95Ms),
            ],
          ),
          const SizedBox(height: AppSpace.cardGap),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SettingsStrings.compared, style: t.titleMedium),
                const SizedBox(height: AppSpace.sm),
                InfoRow(
                  leading: Icon(AppIcons.phone, color: c.primary),
                  label: SettingsStrings.thisPhone,
                  value: s.result == null
                      ? '—'
                      : '${s.result!.p50Ms.toStringAsFixed(1)} ms',
                  valueColor: c.primary,
                ),
                const InfoRow(
                  leading: Icon(Icons.wifi),
                  label: SettingsStrings.serverWifi,
                  value: SettingsStrings.wifiValue,
                ),
                const InfoRow(
                  leading: Icon(Icons.signal_cellular_alt_1_bar),
                  label: SettingsStrings.server3g,
                  value: SettingsStrings.g3Value,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  SettingsStrings.estimateNote,
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          PrimaryButton(
            label: SettingsStrings.runAgain,
            icon: AppIcons.replay,
            onPressed: s.running
                ? null
                : ref.read(speedTestProvider.notifier).run,
          ),
        ],
      ),
    );
  }
}
