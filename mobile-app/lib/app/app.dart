import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/router/app_router.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';
import 'package:leafcheck/features/settings/presentation/settings/app_settings_controller.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_theme.dart';
import 'package:leafcheck/ui/theme/motion.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final GoRouter _router = buildRouter(
    initialLocation: ref.read(appSettingsProvider).onboarded
        ? Routes.scan
        : Routes.onboarding,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: CommonStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      },
      routerConfig: _router,
      builder: (context, child) => ReduceMotionScope(
        enabled: settings.reduceMotion,
        child: child!,
      ),
    );
  }
}
