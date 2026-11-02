import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';

class ModelState {
  const ModelState({
    required this.active,
    required this.phase,
    required this.checkedAt,
    this.previous,
    this.candidate,
    this.progress,
    this.checking = false,
    this.offline = false,
  });

  final ModelRelease active;
  final ModelRelease? previous;
  final ModelUpdatePhase phase;
  final ModelRelease? candidate;
  final DownloadProgress? progress;
  final DateTime checkedAt;
  final bool checking;

  /// The last check failed because there is no connection.
  final bool offline;

  ModelState copyWith({
    ModelRelease? active,
    ModelRelease? previous,
    bool clearPrevious = false,
    ModelUpdatePhase? phase,
    ModelRelease? candidate,
    DownloadProgress? progress,
    DateTime? checkedAt,
    bool? checking,
    bool? offline,
  }) => ModelState(
    active: active ?? this.active,
    previous: clearPrevious ? null : previous ?? this.previous,
    phase: phase ?? this.phase,
    candidate: candidate ?? this.candidate,
    progress: progress ?? this.progress,
    checkedAt: checkedAt ?? this.checkedAt,
    checking: checking ?? this.checking,
    offline: offline ?? this.offline,
  );
}

/// S6: check → download → verify/activate → undo, through the use cases.
class ModelController extends Notifier<ModelState> {
  StreamSubscription<DownloadProgress>? _download;

  @override
  ModelState build() {
    ref.onDispose(() => _download?.cancel());
    final repo = ref.read(modelUpdateRepositoryProvider);
    return ModelState(
      active: repo.active,
      previous: repo.previous,
      phase: ModelUpdatePhase.upToDate,
      checkedAt: repo.checkedAt,
    );
  }

  Future<void> check() async {
    state = state.copyWith(checking: true, offline: false);
    final r = await ref.read(checkForUpdateProvider)();
    final now = ref.read(modelUpdateRepositoryProvider).checkedAt;
    state = switch (r) {
      Ok(value: final ModelRelease v) => state.copyWith(
        phase: ModelUpdatePhase.available,
        candidate: v,
        checkedAt: now,
        checking: false,
      ),
      Ok() => state.copyWith(
        phase: ModelUpdatePhase.upToDate,
        checkedAt: now,
        checking: false,
      ),
      Err(failure: Offline()) => state.copyWith(checking: false, offline: true),
      Err() => state.copyWith(checking: false),
    };
  }

  void download() {
    final candidate = state.candidate;
    if (candidate == null) return;
    final uc = ref.read(downloadAndActivateProvider);
    state = state.copyWith(
      phase: ModelUpdatePhase.downloading,
      progress: DownloadProgress(0, candidate.sizeBytes),
    );
    _download = uc
        .download(candidate)
        .listen(
          (p) => state = state.copyWith(progress: p),
          onDone: () async {
            final r = await uc.activate(candidate);
            final repo = ref.read(modelUpdateRepositoryProvider);
            state = switch (r) {
              Ok() => state.copyWith(
                phase: ModelUpdatePhase.installed,
                active: repo.active,
                previous: repo.previous,
              ),
              Err() => state.copyWith(phase: ModelUpdatePhase.checkFailed),
            };
            ref.invalidate(activeModelProvider);
          },
        );
  }

  Future<void> cancel() async {
    await _download?.cancel();
    state = state.copyWith(phase: ModelUpdatePhase.available);
  }

  /// "Go back to v1" / snackbar "Undo".
  Future<void> rollback() async {
    final r = await ref.read(rollbackModelProvider)();
    if (r is Ok) {
      final repo = ref.read(modelUpdateRepositoryProvider);
      state = state.copyWith(
        active: repo.active,
        clearPrevious: true,
        phase: ModelUpdatePhase.available,
      );
      ref.invalidate(activeModelProvider);
    }
  }
}

final modelControllerProvider =
    NotifierProvider.autoDispose<ModelController, ModelState>(
      ModelController.new,
    );
