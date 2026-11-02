import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';

void main() {
  group('Result', () {
    String describe(Result<int> r) => switch (r) {
      Ok(:final value) => 'ok $value',
      Err(failure: Offline()) => 'offline',
      Err(failure: final f) => 'err ${f.runtimeType}',
    };

    test('switch is exhaustive over Ok and Err', () {
      expect(describe(const Ok(3)), 'ok 3');
      expect(describe(const Err(Offline())), 'offline');
      expect(describe(const Err(ChecksumMismatch())), 'err ChecksumMismatch');
    });
  });

  group('Formatters (exact strings from the designs)', () {
    final now = DateTime(2026, 10, 30, 10, 24);

    test('percent', () {
      expect(Formatters.percent(0.765), '76.5%');
      expect(Formatters.percent(0.981), '98.1%');
      expect(Formatters.percentWhole(0.5), '50%');
    });

    test('relative day and time', () {
      expect(
        Formatters.relativeDayTime(DateTime(2026, 10, 30, 9, 12), now),
        'Today, 09:12',
      );
      expect(
        Formatters.relativeDayTime(DateTime(2026, 10, 29, 16, 40), now),
        'Yesterday, 16:40',
      );
      expect(
        Formatters.relativeDayTime(DateTime(2026, 10, 27, 11, 5), now),
        '27 Oct, 11:05',
      );
      expect(
        Formatters.relativeDay(DateTime(2026, 10, 27), now),
        '27 Oct 2026',
      );
      expect(Formatters.date(DateTime(2026, 10, 29)), '29 Oct 2026');
    });

    test('sizes, ms and sha', () {
      expect(Formatters.megabytes(9437184), '9.0 MB');
      expect(Formatters.megabytesOf(3984589, 9542041), '3.8 of 9.1 MB');
      expect(Formatters.millis(1.9), '1.9 ms');
      expect(
        Formatters.shortSha(
          '83bb87857f2daa43f1fe2f165a46f92af1d22d10b3e324483949e76d0c969b7b',
        ),
        '83bb8785…c969b7b',
      );
    });
  });

  test('MockScenario parses names and defaults to online', () {
    expect(MockScenario.fromName('offline'), MockScenario.offline);
    expect(MockScenario.fromName(''), MockScenario.online);
    expect(MockScenario.fromName('nope'), MockScenario.online);
  });

  test('common strings', () {
    expect(CommonStrings.model('v1'), 'Model v1');
    expect(CommonStrings.reference('d6720fce7b6a40bc'), 'Reference: d6720fce');
    expect(AppAssets.all, hasLength(5));
  });
}
