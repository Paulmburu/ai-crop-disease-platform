import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the layer rules from AGENTS.md by reading every import in lib/.
/// very_good_analysis requires package imports, so every internal import
/// starts with `package:leafcheck/`.
void main() {
  test('layers only import what AGENTS.md allows', () {
    final violations = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      final layer = layerOf(path);
      if (layer == null) continue;
      for (final line in file.readAsLinesSync()) {
        final m = RegExp(r'''^import\s+'([^']+)';''').firstMatch(line.trim());
        if (m == null) continue;
        final why = forbidden(layer, path, m.group(1)!);
        if (why != null) violations.add('$path → ${m.group(1)} ($why)');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('a forbidden import is caught', () {
    expect(
      forbidden(
        'presentation',
        'lib/features/diagnosis/presentation/x.dart',
        'package:leafcheck/features/diagnosis/infrastructure/mock/m.dart',
      ),
      isNotNull,
    );
    expect(
      forbidden(
        'domain',
        'lib/features/diagnosis/domain/x.dart',
        'package:flutter/material.dart',
      ),
      isNotNull,
    );
  });
}

String? layerOf(String path) {
  if (path.startsWith('lib/core/')) return 'core';
  final m = RegExp(
    '^lib/features/[^/]+/(domain|application|infrastructure|presentation)/',
  ).firstMatch(path);
  return m?.group(1);
}

String? forbidden(String layer, String path, String import) {
  const own = 'package:leafcheck/';
  final internal = import.startsWith(own) ? import.substring(own.length) : null;
  final isDart = import.startsWith('dart:');
  final isMeta = import.startsWith('package:meta/');

  switch (layer) {
    case 'core':
    case 'domain':
      if (isDart || isMeta) return null;
      if (internal == null) return 'pure Dart only';
      if (internal.startsWith('core/')) return null;
      if (layer == 'domain' &&
          RegExp('^features/[^/]+/domain/').hasMatch(internal)) {
        return null;
      }
      return 'may only import core/ and domain types';
    case 'application':
      if (isDart || isMeta) return null;
      if (internal == null) return 'no packages in application';
      if (internal.startsWith('core/') ||
          RegExp('^features/[^/]+/(domain|application)/').hasMatch(internal)) {
        return null;
      }
      return 'may only import core/, domain and application';
    case 'infrastructure':
      if (internal != null && internal.contains('/presentation/')) {
        return 'infrastructure must not import presentation';
      }
      if (internal != null &&
          (internal.startsWith('ui/') || internal.startsWith('app/'))) {
        return 'infrastructure must not import ui/ or app/';
      }
      return null;
    case 'presentation':
      if (internal != null && internal.contains('/infrastructure/')) {
        return 'presentation must not import infrastructure';
      }
      if (RegExp(
        '^package:(dio|hive|hive_ce|tflite_flutter|flutter_litert)/',
      ).hasMatch(import)) {
        return 'presentation must not use I/O packages';
      }
      return null;
  }
  return null;
}
