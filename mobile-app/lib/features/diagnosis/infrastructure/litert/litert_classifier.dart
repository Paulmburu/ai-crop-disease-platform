import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/domain/repositories/ports.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/litert/preprocess.dart';
import 'package:leafcheck/features/model_update/infrastructure/model_store.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';

/// On-device diagnosis with LiteRT. Labels, threshold and version come from
/// the active model's metadata; one interpreter is reused per model and
/// reloaded when the active model changes.
class LiteRtClassifier implements Classifier, Benchmark {
  LiteRtClassifier(this.store);

  final ModelStore store;
  Interpreter? _interpreter;
  String? _loadedSha;

  Future<Interpreter> _ready() async {
    final active = store.active;
    if (_loadedSha != active.sha256) {
      _interpreter?.close();
      _interpreter = Interpreter.fromBuffer(await store.bytesOf(active));
      _loadedSha = active.sha256;
    }
    return _interpreter!;
  }

  /// Photo bytes from a bundled sample (`assets/...`) or a file.
  static Future<Uint8List> readPhoto(String path) async =>
      path.startsWith('assets/')
      ? (await rootBundle.load(path)).buffer.asUint8List()
      : File(path).readAsBytes();

  @override
  Future<Result<Prediction>> classify(String imagePath) async {
    final Float32List input;
    try {
      input = await compute(preprocess, await readPhoto(imagePath));
    } on Object {
      return const Err(
        Invalid(code: 'invalid_image', detail: 'This photo could not be read.'),
      );
    }
    try {
      final (probs, ms) = await _run(input);
      final model = store.active;
      return Ok(
        Prediction(
          scores: [
            for (var i = 0; i < model.classLabels.length; i++)
              (
                condition: DiagnosisCondition.fromLabel(model.classLabels[i]),
                probability: probs[i].clamp(0, 1).toDouble(),
              ),
          ],
          threshold: model.threshold,
          modelVersion: model.version,
          latencyMs: ms,
          source: PredictionSource.onDevice,
        ),
      );
    } on Object catch (e) {
      return Err(ModelLoadFailed('$e'));
    }
  }

  // ponytail: inference runs on the UI isolate (a few ms on CPU); switch to
  // IsolateInterpreter if phone benchmarks show jank.
  Future<(Float32List, double)> _run(Float32List input) async {
    final interpreter = await _ready();
    final out = Float32List(store.active.classLabels.length);
    final sw = Stopwatch()..start();
    interpreter.run(input, out);
    return (out, sw.elapsedMicroseconds / 1000);
  }

  /// Speed test (S7-C): inference only, on a fixed input.
  @override
  Future<BenchmarkResult> run(
    int runs, {
    void Function(int done)? onProgress,
  }) async {
    final input = Float32List(224 * 224 * 3)..fillRange(0, 224 * 224 * 3, 0.5);
    await _run(input); // warm-up
    final times = <double>[];
    for (var i = 1; i <= runs; i++) {
      times.add((await _run(input)).$2);
      onProgress?.call(i);
      await Future<void>.delayed(Duration.zero); // let the progress paint
    }
    times.sort();
    double pct(double p) => times[((times.length - 1) * p).round()];
    return BenchmarkResult(p50Ms: pct(0.5), p95Ms: pct(0.95), runs: runs);
  }
}
