import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/ui/theme/motion.dart';

void main() {
  Future<bool> reduced(
    WidgetTester t, {
    bool os = false,
    bool app = false,
  }) async {
    late bool value;
    await t.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: os),
        child: ReduceMotionScope(
          enabled: app,
          child: Builder(
            builder: (c) {
              value = ReduceMotion.of(c);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return value;
  }

  testWidgets('reduce motion follows the OS or the app setting', (t) async {
    expect(await reduced(t), isFalse);
    expect(await reduced(t, os: true), isTrue);
    expect(await reduced(t, app: true), isTrue);
  });

  test('tokens', () {
    expect(AppMotion.short.inMilliseconds, 150);
    expect(AppMotion.medium.inMilliseconds, 300);
    expect(AppMotion.long.inMilliseconds, 500);
  });
}
