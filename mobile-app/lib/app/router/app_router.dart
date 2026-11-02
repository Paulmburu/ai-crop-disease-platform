import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/dev/components_page.dart';
import 'package:leafcheck/app/router/fade_through_branches.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/features/diagnosis/presentation/analyzing/analyzing_page.dart';
import 'package:leafcheck/features/diagnosis/presentation/history/history_page.dart';
import 'package:leafcheck/features/diagnosis/presentation/result/result_page.dart';
import 'package:leafcheck/features/diagnosis/presentation/scan/scan_page.dart';
import 'package:leafcheck/features/library/presentation/disease_detail/disease_detail_page.dart';
import 'package:leafcheck/features/library/presentation/library/library_page.dart';
import 'package:leafcheck/features/model_update/presentation/model/model_page.dart';
import 'package:leafcheck/features/onboarding/presentation/onboarding/onboarding_page.dart';
import 'package:leafcheck/features/settings/presentation/diagnostics/diagnostics_page.dart';
import 'package:leafcheck/features/settings/presentation/settings/settings_page.dart';
import 'package:leafcheck/features/settings/presentation/speed_test/speed_test_page.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/widgets/navigation/app_shell.dart';

/// All routes (UI_IMPLEMENTATION §8). Pages are swapped in phase by phase.
GoRouter buildRouter({String initialLocation = Routes.scan}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute(
      builder: (context, state, shell) => AppShell(
        index: shell.currentIndex,
        onSelect: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        body: shell,
      ),
      navigatorContainerBuilder: (context, shell, children) =>
          FadeThroughBranches(index: shell.currentIndex, children: children),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.scan,
              builder: (_, _) => const ScanPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.history,
              builder: (_, _) => const HistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (_, _) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    // Pushed routes: full screen, no bottom bar.
    GoRoute(
      path: Routes.analyzing,
      pageBuilder: (_, state) => _fade(
        state,
        AnalyzingPage(imagePath: state.extra! as String),
      ),
    ),
    GoRoute(
      path: Routes.diagnosisPattern,
      builder: (_, state) => ResultPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.model,
      pageBuilder: (_, state) => _sharedAxis(state, const ModelPage()),
    ),
    GoRoute(
      path: Routes.diagnostics,
      pageBuilder: (_, state) => _sharedAxis(state, const DiagnosticsPage()),
    ),
    GoRoute(
      path: Routes.speedTest,
      pageBuilder: (_, state) => _sharedAxis(state, const SpeedTestPage()),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (_, _) => const OnboardingPage(),
    ),
    GoRoute(
      path: Routes.library,
      pageBuilder: (_, state) => _sharedAxis(state, const LibraryPage()),
    ),
    GoRoute(
      path: Routes.diseasePattern,
      pageBuilder: (_, state) => _sharedAxis(
        state,
        DiseaseDetailPage(classLabel: state.pathParameters['label']!),
      ),
    ),
    GoRoute(
      path: Routes.devComponents,
      builder: (_, _) => const ComponentsPage(),
    ),
  ],
);

/// Settings → sub-pages: shared axis X, 300 ms (fade with reduce motion).
Page<void> _sharedAxis(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, a, s, child) => ReduceMotion.of(context)
          ? FadeTransition(opacity: a, child: child)
          : SharedAxisTransition(
              animation: a,
              secondaryAnimation: s,
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: Theme.of(context).colorScheme.surface,
              child: child,
            ),
    );

Page<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.short,
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );
