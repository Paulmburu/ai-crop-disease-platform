import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';

/// v1 active; v2 offered in update scenarios; download takes 6 s.
class MockModelUpdateRepository implements ModelUpdateRepository {
  MockModelUpdateRepository(
    this.scenario, {
    required DateTime Function() clock,
    this.step = const Duration(milliseconds: 150),
  }) : _clock = clock,
       _checkedAt = clock().subtract(const Duration(minutes: 4));

  final MockScenario scenario;
  final Duration step;
  final DateTime Function() _clock;
  DateTime _checkedAt;

  static const labels = [
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
  ];

  static final v1 = ModelRelease(
    version: 'v1',
    sizeBytes: 9437184, // 9.0 MB
    sha256: '83bb87857f2daa43f1fe2f165a46f92af1d22d10b3e324483949e76d0c969b7b',
    classLabels: labels,
    threshold: 0.5,
    date: DateTime(2026, 10, 29),
  );

  static final v2 = ModelRelease(
    version: 'v2',
    sizeBytes: 9542041, // 9.1 MB
    sha256: '5f0c2a91c4d7e0b3a6f18e2d9c7b4a5e1f3d6c8b2a9e7f4d1c3b5a8e14d2a0',
    classLabels: labels,
    threshold: 0.5,
    date: DateTime(2026, 10, 30),
  );

  ModelRelease _active = v1;
  ModelRelease? _previous;

  @override
  ModelRelease get active => _active;
  @override
  ModelRelease? get previous => _previous;
  @override
  DateTime get checkedAt => _checkedAt;

  bool get _offersUpdate =>
      scenario == MockScenario.updateAvailable ||
      scenario == MockScenario.checksumFail;

  @override
  Future<Result<ModelRelease?>> check() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (scenario == MockScenario.offline) return const Err(Offline());
    _checkedAt = _clock();
    final offer = _offersUpdate && _active.version != v2.version;
    return Ok(offer ? v2 : null);
  }

  @override
  Stream<DownloadProgress> download(ModelRelease release) async* {
    const steps = 40;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(step);
      yield DownloadProgress(release.sizeBytes * i ~/ steps, release.sizeBytes);
    }
  }

  @override
  Future<Result<ModelRelease>> activate(ModelRelease release) async {
    if (scenario == MockScenario.checksumFail) {
      return const Err(ChecksumMismatch());
    }
    _previous = _active;
    _active = release;
    return Ok(release);
  }

  @override
  Future<Result<ModelRelease>> rollback() async {
    final prev = _previous;
    if (prev == null) {
      return const Err(Invalid(code: 'no_previous', detail: 'No backup model'));
    }
    _previous = null;
    _active = prev;
    return Ok(prev);
  }
}
