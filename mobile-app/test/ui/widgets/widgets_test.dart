import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/app/dev/components_page.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/diagnosis_tone.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/chips/status_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/confidence_bar.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';
import 'package:leafcheck/ui/widgets/feedback/app_snackbar.dart';
import 'package:leafcheck/ui/widgets/feedback/banners.dart';
import 'package:leafcheck/ui/widgets/feedback/empty_state.dart';
import 'package:leafcheck/ui/widgets/feedback/skeleton_lines.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';
import 'package:leafcheck/ui/widgets/navigation/app_shell.dart';
import 'package:leafcheck/ui/widgets/progress/progress_ring.dart';

import '../../helpers.dart';

void main() {
  testWidgets('buttons: sizes, tap and loading', (t) async {
    var taps = 0;
    await pumpThemed(
      t,
      Column(
        children: [
          PrimaryButton(
            label: 'Scan a leaf',
            icon: AppIcons.camera,
            onPressed: () => taps++,
          ),
          TonalButton(label: 'Get advice', onPressed: () => taps++),
          AppTextButton(label: 'Retry', onPressed: () => taps++),
          PrimaryButton(label: 'Busy', onPressed: () {}, loading: true),
        ],
      ),
    );
    expect(
      t.getSize(find.byType(FilledButton).first).height,
      AppSize.primaryButton,
    );
    expect(
      t.getSize(find.byType(FilledButton).at(1)).height,
      AppSize.tonalButton,
    );
    await t.tap(find.text('Scan a leaf'));
    await t.tap(find.text('Get advice'));
    await t.tap(find.text('Retry'));
    expect(taps, 3);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await expectAccessible(t);
  });

  testWidgets('status chip: every tone renders with its label', (t) async {
    await pumpThemed(
      t,
      Wrap(
        children: [
          for (final tone in ChipTone.values)
            StatusChip(label: tone.name, tone: tone, icon: AppIcons.online),
          const StatusChip(
            label: 'Syncing',
            tone: ChipTone.warning,
            busy: true,
          ),
        ],
      ),
    );
    for (final tone in ChipTone.values) {
      expect(find.text(tone.name), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Syncing'), findsOneWidget);
    expect(t.getSize(find.byType(StatusChip).first).height, AppSize.chip);
    await expectAccessible(t);
  });

  testWidgets('diagnosis chip: icon + label for every tone', (t) async {
    await pumpThemed(
      t,
      Column(
        children: [
          for (final tone in DiagnosisTone.values)
            DiagnosisChip(tone: tone, label: tone.name, large: true),
        ],
      ),
    );
    for (final tone in DiagnosisTone.values) {
      expect(find.text(tone.name), findsOneWidget);
      expect(find.byIcon(tone.icon), findsWidgets);
    }
    await expectAccessible(t);
  });

  testWidgets('confidence bar animates; reduce motion jumps to the end', (
    t,
  ) async {
    Widget bar() => const SizedBox(
      width: 300,
      child: Column(
        children: [
          ConfidenceBar(value: 0.765, threshold: 0.5, color: Colors.red),
          CountUpText(value: 76.5, format: _pct),
        ],
      ),
    );
    await pumpThemed(t, bar());
    expect(find.text('0.0%'), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.text('76.5%'), findsOneWidget);

    await pumpThemed(t, bar(), disableAnimations: true);
    await t.pump();
    expect(find.text('76.5%'), findsOneWidget);
  });

  testWidgets('banners, empty state, skeleton, progress', (t) async {
    var retried = false;
    await pumpThemed(
      t,
      SingleChildScrollView(
        child: Column(
          children: [
            OfflineBanner(visible: true, onRetry: () => retried = true),
            const ErrorBanner(title: 'Failed', message: 'Details'),
            const EmptyState(
              icon: AppIcons.history,
              title: 'No diagnoses yet',
              message: 'Scan a leaf.',
              footer: 'Reference: abcd1234',
            ),
            const SkeletonLines(),
            const ProgressRing(value: 0.42),
            const ProgressRing(value: 1),
          ],
        ),
      ),
      disableAnimations: true,
    );
    await t.pump();
    await t.tap(find.text('Retry'));
    expect(retried, isTrue);
    expect(find.text("You're offline. Diagnosis still works."), findsOneWidget);
    expect(find.text('Reference: abcd1234'), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await expectAccessible(t);
  });

  testWidgets('layout widgets', (t) async {
    await pumpThemed(
      t,
      const SectionCard(
        child: Column(
          children: [
            SectionHeader(title: 'Recent'),
            InfoRow(label: 'Size', value: '9.0 MB'),
            IconTextRow(icon: AppIcons.sun, text: 'Use daylight'),
          ],
        ),
      ),
    );
    expect(find.text('9.0 MB'), findsOneWidget);
    expect(find.text('Use daylight'), findsOneWidget);
  });

  testWidgets('snackbar and bottom sheet', (t) async {
    await pumpThemed(
      t,
      Builder(
        builder: (c) => Column(
          children: [
            TextButton(
              onPressed: () => AppSnackbar.show(
                c,
                'Synced 12 diagnoses',
                actionLabel: 'View',
              ),
              child: const Text('snack'),
            ),
            TextButton(
              onPressed: () => AppBottomSheet.show<void>(
                c,
                builder: (_) => const Text('sheet body'),
              ),
              child: const Text('sheet'),
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('snack'));
    await t.pumpAndSettle();
    expect(find.text('Synced 12 diagnoses'), findsOneWidget);
    await t.tap(find.text('sheet'));
    await t.pumpAndSettle();
    expect(find.text('sheet body'), findsOneWidget);
  });

  testWidgets('app shell: three destinations, selection callback', (t) async {
    var selected = 0;
    await pumpThemed(
      t,
      AppShell(index: 0, onSelect: (i) => selected = i, body: const SizedBox()),
      scaffold: false,
    );
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await t.tap(find.text('History'));
    expect(selected, 1);
    expect(
      t.getSize(find.byType(NavigationBar)).height,
      greaterThanOrEqualTo(AppSize.navBar),
    );
    await expectAccessible(t);
  });

  testWidgets('components page renders (light and dark)', (t) async {
    for (final dark in [false, true]) {
      await pumpThemed(
        t,
        const ComponentsPage(),
        dark: dark,
        scaffold: false,
        disableAnimations: true,
      );
      await t.pump();
      expect(find.text('Components'), findsOneWidget);
      expect(t.takeException(), isNull);
    }
  });
}

String _pct(double v) => '${v.toStringAsFixed(1)}%';
