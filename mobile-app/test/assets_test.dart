import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';

void main() {
  test('bundled images load', () async {
    for (final path in AppAssets.all) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(10000), reason: path);
    }
  });
}
