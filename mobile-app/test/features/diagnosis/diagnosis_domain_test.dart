import 'package:flutter_test/flutter_test.dart';
import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/application/use_cases.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/mock/diagnosis_mock_data.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/mock/mock_diagnosis_adapters.dart';

import '../../helpers.dart';

void main() {
  final now = DateTime(2026, 10, 30, 10, 24);

  group('domain', () {
    test('labels map to conditions and back', () {
      for (final c in DiagnosisCondition.values) {
        expect(DiagnosisCondition.fromLabel(c.label), c);
      }
      expect(() => DiagnosisCondition.fromLabel('Tomato'), throwsArgumentError);
    });

    test('status rule: top-1 below threshold is uncertain', () {
      expect(DiagnosisMockData.lateBlight.status, DiagnosisStatus.confident);
      expect(DiagnosisMockData.uncertain.status, DiagnosisStatus.uncertain);
    });

    test('scores are sorted best first and validated', () {
      final p = DiagnosisMockData.prediction([
        (DiagnosisCondition.healthy, 0.1),
        (DiagnosisCondition.lateBlight, 0.9),
      ]);
      expect(p.top.condition, DiagnosisCondition.lateBlight);
      expect(
        () => Prediction(
          scores: const [],
          threshold: 0.5,
          modelVersion: 'v1',
          latencyMs: 1,
          source: PredictionSource.onDevice,
        ),
        throwsArgumentError,
      );
      expect(
        () => DiagnosisMockData.prediction([(DiagnosisCondition.healthy, 1.2)]),
        throwsArgumentError,
      );
    });
  });

  group('use cases on mocks', () {
    late MockDiagnosisRepository repo;
    setUp(
      () => repo = MockDiagnosisRepository(
        DiagnosisMockData.history(now, MockScenario.online),
      ),
    );

    test('DiagnoseLeaf saves before returning, as pending', () async {
      final uc = DiagnoseLeaf(
        classifier: MockClassifier(MockScenario.online, delay: Duration.zero),
        repository: repo,
        clock: () => now,
        newId: () => 'new-1',
        deviceId: DiagnosisMockData.deviceId,
      );
      final r = await uc(DiagnosisMockData.lateBlightPhoto);
      final d = r.okValue;
      expect(d.condition, DiagnosisCondition.lateBlight);
      expect(d.confidence, 0.765);
      expect(d.syncState, SyncState.pending);
      expect(await repo.get('new-1'), isNotNull);
    });

    test('uncertain scenario gives "not sure"', () async {
      final r = await MockClassifier(
        MockScenario.uncertainPhoto,
        delay: Duration.zero,
      ).classify(DiagnosisMockData.lateBlightPhoto);
      expect(r.okValue.status, DiagnosisStatus.uncertain);
    });

    test(
      'history matches the designs and sync flips pending → synced',
      () async {
        final all = await repo.watchAll().first;
        expect(all.first.id, 'd-0912');
        expect(pendingCount(all), 2);
        expect(
          all.where((d) => d.syncState == SyncState.rejected),
          hasLength(1),
        );

        final sync = MockSyncService(
          repo,
          MockScenario.online,
          clock: () => now,
          delay: Duration.zero,
        );
        expect(sync.lastSyncAt, DateTime(2026, 10, 30, 8, 55));
        final r = await SyncDiagnoses(sync)();
        expect(r.okValue, 2);
        expect(pendingCount(await repo.watchAll().first), 0);
      },
    );

    test('offline: sync and second opinion fail with Offline', () async {
      final sync = MockSyncService(
        repo,
        MockScenario.offline,
        clock: () => now,
        delay: Duration.zero,
      );
      expect(await sync.syncPending(), isA<Err<int>>());
      final d = (await repo.get('d-0912'))!;
      final r = await SecondOpinion(
        server: MockServerClassifier(
          MockScenario.offline,
          delay: Duration.zero,
        ),
        repository: repo,
      )(d);
      expect(r.errFailure, isA<Offline>());
    });

    test('second opinion is stored on the diagnosis', () async {
      final d = (await repo.get('d-0912'))!;
      final r = await SecondOpinion(
        server: MockServerClassifier(MockScenario.online, delay: Duration.zero),
        repository: repo,
      )(d);
      expect(r.okValue.secondOpinion!.top.probability, 0.812);
    });

    test('first run has no history; delete removes', () async {
      expect(DiagnosisMockData.history(now, MockScenario.firstRun), isEmpty);
      await DeleteDiagnosis(repo)('d-0912');
      expect(await GetDiagnosis(repo)('d-0912'), isA<Err<dynamic>>());
    });
  });
}
