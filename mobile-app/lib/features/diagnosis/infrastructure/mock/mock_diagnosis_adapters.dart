import 'dart:async';

import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/repositories/ports.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/mock/diagnosis_mock_data.dart';

/// In-memory store seeded with the design data.
class MockDiagnosisRepository implements DiagnosisRepository {
  MockDiagnosisRepository(List<Diagnosis> seed)
    : _items = {for (final d in seed) d.id: d};

  final Map<String, Diagnosis> _items;
  final _changes = StreamController<List<Diagnosis>>.broadcast();

  List<Diagnosis> get _sorted =>
      _items.values.toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

  @override
  Stream<List<Diagnosis>> watchAll() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  @override
  Future<Diagnosis?> get(String id) async => _items[id];

  @override
  Future<void> save(Diagnosis d) async {
    _items[d.id] = d;
    _changes.add(_sorted);
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _changes.add(_sorted);
  }
}

/// On-device classifier stand-in: 900 ms, result chosen by the photo.
class MockClassifier implements Classifier {
  MockClassifier(
    this.scenario, {
    this.delay = const Duration(milliseconds: 900),
  });

  final MockScenario scenario;
  final Duration delay;

  @override
  Future<Result<Prediction>> classify(String imagePath) async {
    await Future<void>.delayed(delay);
    return Ok(
      scenario == MockScenario.uncertainPhoto
          ? DiagnosisMockData.uncertain
          : DiagnosisMockData.forPhoto(imagePath),
    );
  }
}

/// Server classifier stand-in (second opinion). Fails when offline.
class MockServerClassifier implements Classifier {
  MockServerClassifier(
    this.scenario, {
    this.delay = const Duration(seconds: 1),
  });

  final MockScenario scenario;
  final Duration delay;

  @override
  Future<Result<Prediction>> classify(String imagePath) async {
    await Future<void>.delayed(delay);
    if (scenario == MockScenario.offline) return const Err(Offline());
    return Ok(DiagnosisMockData.serverLateBlight);
  }
}

/// Flips pending → syncing → synced (1.5 s). Offline → `Offline`.
class MockSyncService implements SyncService {
  MockSyncService(
    this.repository,
    this.scenario, {
    required DateTime Function() clock,
    this.delay = const Duration(milliseconds: 1500),
  }) : _clock = clock,
       _lastSync = clock().subtract(const Duration(hours: 1, minutes: 29));

  final MockDiagnosisRepository repository;
  final MockScenario scenario;
  final Duration delay;
  final DateTime Function() _clock;
  DateTime? _lastSync;

  @override
  DateTime? get lastSyncAt => _lastSync;

  @override
  Future<Result<int>> syncPending() async {
    if (scenario == MockScenario.offline) return const Err(Offline());
    final pending = (await repository.watchAll().first)
        .where((d) => d.syncState == SyncState.pending)
        .toList();
    for (final d in pending) {
      await repository.save(d.copyWith(syncState: SyncState.syncing));
    }
    await Future<void>.delayed(delay);
    for (final d in pending) {
      await repository.save(d.copyWith(syncState: SyncState.synced));
    }
    _lastSync = _clock();
    return Ok(pending.length);
  }
}
