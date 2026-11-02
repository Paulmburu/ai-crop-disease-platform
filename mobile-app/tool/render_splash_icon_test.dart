// Renders the splash/launcher artwork from the theme (run on demand):
//   flutter test --update-goldens tool/render_splash_icon_test.dart
// Writes assets/splash/splash_icon.png (light) and splash_icon_dark.png.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

import '../test/flutter_test_config.dart' as cfg;

void main() => cfg.testExecutable(() {
  for (final (name, bg, fg) in [
    ('splash_icon', LightTokens.primaryContainer, LightTokens.primary),
    (
      'splash_icon_dark',
      DarkTokens.primaryContainer,
      DarkTokens.onPrimaryContainer,
    ),
  ]) {
    testWidgets(name, (t) async {
      t.view
        ..physicalSize = const Size(1152, 1152)
        ..devicePixelRatio = 1;
      addTearDown(t.view.reset);
      // Android 12 splash: the icon must fit a 768 px circle in 1152 px.
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              child: Container(
                width: 1152,
                height: 1152,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 520,
                  height: 520,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(150),
                  ),
                  child: Icon(Icons.eco, size: 300, color: fg),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../assets/splash/$name.png'),
      );
    });
  }
});
