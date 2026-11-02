import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/features/diagnosis/presentation/analyzing/analyzing_page.dart';
import 'package:leafcheck/features/diagnosis/presentation/analyzing/widgets/scan_line_overlay.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';

import '../../../helpers.dart';

void main() {
  for (final (id, progress) in [
    ('s2_a_analyzing_start', 0.05),
    ('s2_b_analyzing_end', 0.95),
  ]) {
    testWidgets('$id key frame', (t) async {
      await pumpPage(
        t,
        AnalyzingPage(
          imagePath: AppAssets.leafLateBlight,
          scanProgress: progress,
        ),
      );
      expect(find.text('Checking the leaf…'), findsOneWidget);
      expect(find.text('On this phone · no internet needed'), findsOneWidget);
      expect(find.byType(ScanLineOverlay), findsOneWidget);
      await loadImages(t);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenFile(id)),
      );
      // Let the min-hold timer finish before the test ends.
      await t.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('scan → sample photo → analyzing → result', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Scan a leaf'));
    await t.pumpAndSettle();
    await t.tap(find.text('Take photo'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('leaf_late_blight.jpg'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Checking the leaf…'), findsOneWidget);
    await t.pump(const Duration(seconds: 1)); // min hold
    await t.pumpAndSettle();
    expect(find.text('Checking the leaf…'), findsNothing);
    expect(find.textContaining('Result'), findsWidgets);
  });
}
