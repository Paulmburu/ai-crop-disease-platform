import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/features/settings/presentation/settings/app_settings_controller.dart';
import 'package:leafcheck/features/settings/presentation/settings/widgets/settings_widgets.dart';
import 'package:leafcheck/features/settings/presentation/settings/widgets/theme_segmented.dart';
import 'package:leafcheck/features/settings/presentation/shared/backend_status_provider.dart';
import 'package:leafcheck/features/settings/presentation/strings/settings_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// S7-A Settings (third tab).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final ctrl = ref.read(appSettingsProvider.notifier);
    final model = ref.watch(activeModelProvider);
    final status = ref.watch(backendStatusProvider).value;
    final down = status?.services.where((x) => !x.ok).length ?? 0;
    final statusText = switch (status) {
      null => '',
      _ when !status.online => SettingsStrings.offline,
      _ when down == 0 => SettingsStrings.allWorking,
      _ => SettingsStrings.issues(down),
    };
    final id = s.deviceId;
    final shortId = '${id.substring(0, 8)}-…-${id.substring(id.length - 4)}';

    return Scaffold(
      appBar: AppBar(title: const Text(SettingsStrings.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.xl,
        ),
        children: [
          SettingsSection(
            title: SettingsStrings.sectionDiagnosis,
            rows: [
              SettingsRow(
                icon: AppIcons.model,
                title: SettingsStrings.diagnosisModel,
                subtitle: SettingsStrings.modelSummary(
                  model.version,
                  upToDate: true,
                ),
                onTap: () => context.push(Routes.model),
              ),
            ],
          ),
          SettingsSection(
            title: SettingsStrings.sectionServer,
            rows: [
              SettingsRow(
                icon: AppIcons.server,
                title: SettingsStrings.serverAddress,
                subtitle: '${s.serverUrl} · ${SettingsStrings.androidEmulator}',
              ),
              SettingsRow(
                icon: AppIcons.key,
                title: SettingsStrings.accessKey,
                subtitle: s.hasAccessKey
                    ? SettingsStrings.keySet
                    : SettingsStrings.keyMissing,
              ),
              SettingsRow(
                icon: AppIcons.health,
                title: SettingsStrings.diagnostics,
                subtitle: statusText,
                onTap: () => context.push(Routes.diagnostics),
              ),
            ],
          ),
          SettingsSection(
            title: SettingsStrings.sectionDisplay,
            rows: [
              SettingsRow(
                icon: AppIcons.darkMode,
                title: SettingsStrings.theme,
                trailing: ThemeSegmented(
                  value: s.theme,
                  onChanged: ctrl.setTheme,
                ),
              ),
              SettingsRow(
                icon: AppIcons.motionOff,
                title: SettingsStrings.reduceMotion,
                trailing: Semantics(
                  label: SettingsStrings.reduceMotion,
                  child: Switch(
                    value: s.reduceMotion,
                    onChanged: (v) => ctrl.setReduceMotion(value: v),
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: SettingsStrings.sectionAbout,
            rows: [
              SettingsRow(
                icon: AppIcons.phone,
                title: SettingsStrings.deviceId,
                subtitle: shortId,
              ),
              const SettingsRow(
                icon: AppIcons.info,
                title: SettingsStrings.version,
                subtitle: SettingsStrings.appVersion,
              ),
            ],
          ),
          if (kDebugMode)
            SettingsSection(
              title: SettingsStrings.sectionDebug,
              rows: [
                SettingsRow(
                  icon: AppIcons.build,
                  title: SettingsStrings.mockScenario,
                  subtitle:
                      ref.watch(scenarioProvider)?.name ??
                      SettingsStrings.realBackend,
                  onTap: () => context.push(Routes.devComponents),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
