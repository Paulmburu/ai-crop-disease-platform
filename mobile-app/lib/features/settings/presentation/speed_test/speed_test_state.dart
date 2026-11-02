import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/constants/app_constants.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';

class SpeedTestState {
  const SpeedTestState({this.done = 0, this.result});
  final int done;
  final BenchmarkResult? result;
  bool get running => result == null && done > 0;
}

/// Runs the on-device benchmark when the page opens; "Run again" reruns it.
class SpeedTestController extends Notifier<SpeedTestState> {
  @override
  SpeedTestState build() {
    unawaited(Future.microtask(run));
    return const SpeedTestState();
  }

  Future<void> run() async {
    state = const SpeedTestState(done: 1);
    final r = await ref.read(runSpeedTestProvider)(
      AppConstants.speedTestRuns,
      onProgress: (n) => state = SpeedTestState(done: n),
    );
    state = SpeedTestState(done: r.runs, result: r);
  }
}

final speedTestProvider =
    NotifierProvider.autoDispose<SpeedTestController, SpeedTestState>(
      SpeedTestController.new,
    );
