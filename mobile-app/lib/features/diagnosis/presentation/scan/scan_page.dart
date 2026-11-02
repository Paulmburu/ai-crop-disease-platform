import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/features/diagnosis/presentation/scan/scan_state.dart';
import 'package:leafcheck/features/diagnosis/presentation/scan/widgets/photo_source_sheet.dart';
import 'package:leafcheck/features/diagnosis/presentation/scan/widgets/photo_tips_card.dart';
import 'package:leafcheck/features/diagnosis/presentation/scan/widgets/recent_section.dart';
import 'package:leafcheck/features/diagnosis/presentation/scan/widgets/scan_hero_card.dart';
import 'package:leafcheck/features/diagnosis/presentation/scan/widgets/status_row.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/feedback/banners.dart';

/// S1 Scan (designs s1_a / s1_b / s1_c + s1a sheet).
class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  Future<void> _scan(BuildContext context) async {
    final path = await PhotoSourceSheet.show(context);
    if (path != null && context.mounted) {
      await context.push(Routes.analyzing, extra: path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanStateProvider);
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(
        title: const Text(CommonStrings.appName),
        actions: [
          IconButton(
            tooltip: DiagnosisStrings.help,
            icon: const Icon(AppIcons.help),
            onPressed: () => context.push(Routes.library),
          ),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => Column(
          children: [
            OfflineBanner(
              visible: !value.online,
              onRetry: () => retryConnection(ref),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.md,
                  AppSpace.screen,
                  AppSpace.xl,
                ),
                children: [
                  StatusRow(
                    modelVersion: value.modelVersion,
                    online: value.online,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  ScanHeroCard(onScan: () => _scan(context)),
                  const SizedBox(height: AppSpace.xl),
                  if (value.firstRun)
                    const PhotoTipsCard()
                  else
                    RecentSection(
                      items: value.recent,
                      now: now,
                      onOpen: (d) => context.push(Routes.diagnosis(d.id)),
                      onSeeAll: () => context.go(Routes.history),
                    ),
                ],
              ),
            ),
          ],
        ),
        AsyncError() => const SizedBox.shrink(),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
