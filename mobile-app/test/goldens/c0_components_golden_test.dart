import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/app/dev/components_page.dart';

import '../helpers.dart';

/// Visual reference for side-by-side review with
/// designs/c0_component_reference/screen.png (not a pixel-equality check).
/// Asset photos don't decode in golden tests; they're checked on the emulator.
void main() {
  testWidgets('c0 component reference', (t) async {
    await pumpThemed(
      t,
      const ComponentsPage(),
      scaffold: false,
      disableAnimations: true,
    );
    t.view.physicalSize = const Size(412, 2200) * shotDpr.toDouble();
    await t.pump(const Duration(seconds: 1));
    await loadImages(t);
    await expectLater(
      find.byType(ComponentsPage),
      matchesGoldenFile(goldenFile('c0_component_reference')),
    );
  });
}
