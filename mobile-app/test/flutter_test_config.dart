import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled Inter font so widget and golden tests render real text
/// instead of the Ahem test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Inter');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Italic']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$f.ttf'));
  }
  await loader.load();
  // Material icons, so goldens show real icons instead of boxes.
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  await testMain();
}
