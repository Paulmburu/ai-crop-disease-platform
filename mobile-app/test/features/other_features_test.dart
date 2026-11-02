import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/advice/application/ask_advice.dart';
import 'package:leafcheck/features/advice/infrastructure/mock/mock_advice_repository.dart';
import 'package:leafcheck/features/model_update/application/model_update_use_cases.dart';
import 'package:leafcheck/features/model_update/infrastructure/mock/mock_model_update_repository.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';
import 'package:leafcheck/features/settings/infrastructure/mock/mock_settings_adapters.dart';

import '../helpers.dart';

void main() {
  DateTime now() => DateTime(2026, 10, 30, 10, 24);
  const late = 'Potato___Late_blight';

  group('advice', () {
    AskAdvice uc(MockScenario s) =>
        AskAdvice(MockAdviceRepository(s, delay: Duration.zero));

    test('answer with two citations', () async {
      final r = await uc(MockScenario.online)('What should I do today?', late);
      final a = r.okValue;
      expect(a.citations, hasLength(2));
      expect(a.text, contains('[2]'));
    });

    test('too short question is rejected locally', () async {
      final r = await uc(MockScenario.online)('?', late);
      expect(r.errFailure, isA<Invalid>());
    });

    test('offline and advice-down failures', () async {
      expect(
        (await uc(MockScenario.offline)('What now?', late)).errFailure,
        isA<Offline>(),
      );
      final down =
          (await uc(MockScenario.adviceDown)('What now?', late)) as Err;
      expect((down.errFailure as ServerUnavailable).code, 'advice_unavailable');
    });
  });

  group('model update', () {
    test('up to date in the online scenario', () async {
      final repo = MockModelUpdateRepository(MockScenario.online, clock: now);
      expect((await CheckForUpdate(repo)()).okValue, isNull);
      expect(repo.active.version, 'v1');
    });

    test('update: download, activate, roll back', () async {
      final repo = MockModelUpdateRepository(
        MockScenario.updateAvailable,
        clock: now,
        step: Duration.zero,
      );
      final v2 = (await CheckForUpdate(repo)()).okValue!;
      final uc = DownloadAndActivate(repo);
      final last = await uc.download(v2).last;
      expect(last.done, isTrue);
      expect(await uc.activate(v2), isA<Ok<dynamic>>());
      expect(repo.active.version, 'v2');
      expect(repo.previous!.version, 'v1');
      await RollbackModel(repo)();
      expect(repo.active.version, 'v1');
    });

    test('checksum failure keeps v1', () async {
      final repo = MockModelUpdateRepository(
        MockScenario.checksumFail,
        clock: now,
        step: Duration.zero,
      );
      final v2 = (await CheckForUpdate(repo)()).okValue!;
      final r = await DownloadAndActivate(repo).activate(v2);
      expect(r.errFailure, isA<ChecksumMismatch>());
      expect(repo.active.version, 'v1');
    });
  });

  group('settings and status', () {
    test('advice down shows only advice as down', () async {
      final s = await MockBackendStatusSource(
        MockScenario.adviceDown,
        clock: now,
      ).watch().first;
      expect(s.isUp(ServiceName.server), isTrue);
      expect(s.isUp(ServiceName.advice), isFalse);
    });

    test('offline status', () async {
      final s = await MockBackendStatusSource(
        MockScenario.offline,
        clock: now,
      ).watch().first;
      expect(s.online, isFalse);
    });

    test('settings save and benchmark result', () async {
      final repo = MockSettingsRepository();
      await repo.save(repo.load().copyWith(theme: ThemePreference.dark));
      expect(repo.load().theme, ThemePreference.dark);
      var progress = 0;
      final r = await MockBenchmark(
        perRun: Duration.zero,
      ).run(10, onProgress: (n) => progress = n);
      expect(progress, 10);
      expect(r.p50Ms, 1.9);
    });
  });
}
