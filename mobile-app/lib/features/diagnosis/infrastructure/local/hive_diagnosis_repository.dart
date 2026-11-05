import 'dart:async';
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/domain/repositories/ports.dart';

/// Diagnoses as plain maps in a Hive box; photos copied into [photoDir] so
/// they outlive the picker's temp files.
class HiveDiagnosisRepository implements DiagnosisRepository {
  HiveDiagnosisRepository(this._box, this.photoDir);

  final Box<dynamic> _box;
  final Directory photoDir;
  final _changes = StreamController<List<Diagnosis>>.broadcast();

  List<Diagnosis> get _sorted =>
      _box.values.whereType<Map<dynamic, dynamic>>().map(fromMap).toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

  @override
  Stream<List<Diagnosis>> watchAll() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  @override
  Future<Diagnosis?> get(String id) async {
    final m = _box.get(id);
    return m is Map ? fromMap(m) : null;
  }

  @override
  Future<void> save(Diagnosis d) async {
    await _box.put(d.id, toMap(d, await _keepPhoto(d)));
    _changes.add(_sorted);
  }

  @override
  Future<void> delete(String id) async {
    final d = await get(id);
    await _box.delete(id);
    if (d != null && d.imagePath.startsWith(photoDir.path)) {
      final f = File(d.imagePath);
      if (f.existsSync()) await f.delete();
    }
    _changes.add(_sorted);
  }

  Future<String> _keepPhoto(Diagnosis d) async {
    final p = d.imagePath;
    if (p.startsWith('assets/') || p.startsWith(photoDir.path)) return p;
    await photoDir.create(recursive: true);
    final ext = p.contains('.') ? p.substring(p.lastIndexOf('.')) : '.jpg';
    return (await File(p).copy('${photoDir.path}/${d.id}$ext')).path;
  }

  static Map<String, Object?> toMap(Diagnosis d, String imagePath) => {
    'id': d.id,
    'device_id': d.deviceId,
    'prediction': _predictionToMap(d.prediction),
    'captured_at': d.capturedAt.toUtc().toIso8601String(),
    'image_path': imagePath,
    'sync_state': d.syncState.name,
    'reject_reason': d.rejectReason,
    'second_opinion': d.secondOpinion == null
        ? null
        : _predictionToMap(d.secondOpinion!),
  };

  static Diagnosis fromMap(Map<dynamic, dynamic> m) => Diagnosis(
    id: m['id'] as String,
    deviceId: m['device_id'] as String,
    prediction: _predictionFromMap(m['prediction'] as Map),
    capturedAt: DateTime.parse(m['captured_at'] as String).toLocal(),
    imagePath: m['image_path'] as String,
    syncState: SyncState.values.byName(m['sync_state'] as String),
    rejectReason: m['reject_reason'] as String?,
    secondOpinion: m['second_opinion'] == null
        ? null
        : _predictionFromMap(m['second_opinion'] as Map),
  );

  static Map<String, Object?> _predictionToMap(Prediction p) => {
    'scores': [
      for (final s in p.scores)
        {'label': s.condition.label, 'p': s.probability},
    ],
    'threshold': p.threshold,
    'model_version': p.modelVersion,
    'latency_ms': p.latencyMs,
    'source': p.source.name,
  };

  static Prediction _predictionFromMap(Map<dynamic, dynamic> m) => Prediction(
    scores: [
      for (final s in (m['scores'] as List).cast<Map<dynamic, dynamic>>())
        (
          condition: DiagnosisCondition.fromLabel(s['label'] as String),
          probability: (s['p'] as num).toDouble(),
        ),
    ],
    threshold: (m['threshold'] as num).toDouble(),
    modelVersion: m['model_version'] as String,
    latencyMs: (m['latency_ms'] as num).toDouble(),
    source: PredictionSource.values.byName(m['source'] as String),
  );
}
