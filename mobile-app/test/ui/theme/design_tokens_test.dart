import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/ui/theme/app_theme.dart';
import 'package:leafcheck/ui/theme/diagnosis_colors.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// Guards against drift between the code tokens and the Stitch export
/// `designs/field_diagnostic_tool/DESIGN.md` (YAML front matter).
void main() {
  final yaml = _frontMatter(
    File('designs/field_diagnostic_tool/DESIGN.md').readAsLinesSync(),
  );

  test('colour tokens match DESIGN.md (except documented overrides)', () {
    const overrides = {'primary'}; // UI_IMPLEMENTATION §1
    const s = AppTheme.lightScheme;
    const d = DiagnosisColors.light;
    final code = <String, Color>{
      'on-primary': s.onPrimary,
      'primary-container': s.primaryContainer,
      'on-primary-container': s.onPrimaryContainer,
      'inverse-primary': s.inversePrimary,
      'secondary': s.secondary,
      'secondary-container': s.secondaryContainer,
      'on-secondary-container': s.onSecondaryContainer,
      'surface': s.surface,
      'surface-dim': s.surfaceDim,
      'surface-container-lowest': s.surfaceContainerLowest,
      'surface-container-low': s.surfaceContainerLow,
      'surface-container': s.surfaceContainer,
      'surface-container-high': s.surfaceContainerHigh,
      'surface-container-highest': s.surfaceContainerHighest,
      'on-surface': s.onSurface,
      'on-surface-variant': s.onSurfaceVariant,
      'inverse-surface': s.inverseSurface,
      'inverse-on-surface': s.onInverseSurface,
      'outline': s.outline,
      'outline-variant': s.outlineVariant,
      'error': s.error,
      'error-container': s.errorContainer,
      'on-error-container': s.onErrorContainer,
      'diag-healthy': d.healthy.main,
      'diag-healthy-container': d.healthy.container,
      'diag-healthy-text': d.healthy.onContainer,
      'diag-early-blight': d.earlyBlight.main,
      'diag-early-blight-bar': d.earlyBlight.bar,
      'diag-early-blight-container': d.earlyBlight.container,
      'diag-early-blight-text': d.earlyBlight.onContainer,
      'diag-late-blight': d.lateBlight.main,
      'diag-late-blight-container': d.lateBlight.container,
      'diag-late-blight-text': d.lateBlight.onContainer,
      'diag-uncertain': d.uncertain.main,
      'diag-uncertain-container': d.uncertain.container,
      'diag-uncertain-text': d.uncertain.onContainer,
    };
    final colors = yaml['colors']!;
    for (final e in code.entries) {
      expect(colors[e.key], isNotNull, reason: '${e.key} missing in DESIGN.md');
      expect(_hex(e.value), colors[e.key]!.toUpperCase(), reason: e.key);
    }
    expect(overrides, everyElement(isIn(colors.keys)));
    expect(s.primary, LightTokens.primary);
  });

  test('type scale matches DESIGN.md', () {
    final t = AppTheme.light.textTheme;
    final roles = <String, TextStyle?>{
      'headline-lg': t.headlineLarge,
      'headline-md': t.headlineMedium,
      'headline-sm': t.headlineSmall,
      'title-lg': t.titleLarge,
      'title-md': t.titleMedium,
      'title-sm': t.titleSmall,
      'body-lg': t.bodyLarge,
      'body-md': t.bodyMedium,
      'body-sm': t.bodySmall,
      'label-lg': t.labelLarge,
      'label-md': t.labelMedium,
      'label-sm': t.labelSmall,
    };
    for (final e in roles.entries) {
      final spec = yaml['typography.${e.key}']!;
      final style = e.value!;
      double px(String k) => double.parse(spec[k]!.replaceAll('px', ''));
      expect(style.fontSize, px('fontSize'), reason: e.key);
      expect(
        style.fontSize! * style.height!,
        closeTo(px('lineHeight'), 0.01),
        reason: e.key,
      );
      expect(
        style.fontWeight!.value,
        int.parse(spec['fontWeight']!),
        reason: e.key,
      );
      if (spec.containsKey('letterSpacing')) {
        expect(style.letterSpacing, px('letterSpacing'), reason: e.key);
      }
      expect(style.fontFamily, 'Inter');
    }
  });

  test('component themes follow DESIGN.md components', () {
    final th = AppTheme.light;
    expect(th.navigationBarTheme.height, AppSize.navBar);
    final btn = th.filledButtonTheme.style!;
    expect(btn.minimumSize!.resolve({})!.height, AppSize.primaryButton);
    final shape = btn.shape!.resolve({})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(AppRadius.button));
    expect(th.cardTheme.color, th.colorScheme.surfaceContainerLow);
    expect(th.extension<DiagnosisColors>(), DiagnosisColors.light);
    expect(AppTheme.dark.extension<DiagnosisColors>(), DiagnosisColors.dark);
  });

  test('diagnosis colours interpolate', () {
    final mid = DiagnosisColors.light.lerp(DiagnosisColors.dark, 0.5);
    expect(mid.healthy.main, isNot(DiagnosisColors.light.healthy.main));
  });
}

String _hex(Color c) {
  final rgb = (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return '#${rgb.toUpperCase()}';
}

/// Tiny parser for the DESIGN.md front matter: `colors` (flat map) and
/// `typography.<role>` (nested maps). Enough for this file; not general YAML.
Map<String, Map<String, String>> _frontMatter(List<String> lines) {
  final out = <String, Map<String, String>>{};
  var section = '';
  var role = '';
  for (final raw in lines.skip(1)) {
    if (raw.trim() == '---') break;
    if (raw.trim().isEmpty) continue;
    final indent = raw.length - raw.trimLeft().length;
    final parts = raw.trim().split(':');
    final key = parts.first.trim();
    final value = parts.skip(1).join(':').trim().replaceAll("'", '');
    if (indent == 0) {
      section = key;
      out.putIfAbsent(section, () => {});
    } else if (section == 'typography' && indent == 2) {
      role = key;
      out['typography.$role'] = {};
    } else if (section == 'typography') {
      out['typography.$role']![key] = value;
    } else {
      out[section]![key] = value;
    }
  }
  return out;
}
