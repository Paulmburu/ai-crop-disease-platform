import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_ce/hive.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';

/// Which model is active, where its file is, and the previous one (kept for
/// rollback). The bundled v1 is the last fallback. State lives in Hive.
class ModelStore {
  ModelStore._(this._box, this._dir, this.bundled, this._bundledBytes);

  static const bundledModel = 'assets/models/crop_disease_v1.tflite';
  static const bundledMeta = 'assets/models/crop_disease_v1.json';

  static Future<ModelStore> open(Box<dynamic> box, Directory dir) async {
    final bytes = (await rootBundle.load(bundledModel)).buffer.asUint8List();
    final meta =
        jsonDecode(await rootBundle.loadString(bundledMeta))
            as Map<String, dynamic>;
    final installed = DateTime.parse(
      (box.get('bundled_installed') as String?) ??
          DateTime.now().toUtc().toIso8601String(),
    );
    await box.put('bundled_installed', installed.toIso8601String());
    final bundled = ModelRelease(
      version: meta['model_version'] as String,
      sizeBytes: bytes.length,
      sha256: sha256.convert(bytes).toString(),
      classLabels: List<String>.from(meta['class_names'] as List),
      threshold: (meta['confidence_threshold'] as num).toDouble(),
      date: installed.toLocal(),
    );
    await dir.create(recursive: true);
    return ModelStore._(box, dir, bundled, bytes);
  }

  final Box<dynamic> _box;
  final Directory _dir;
  final ModelRelease bundled;
  final Uint8List _bundledBytes;

  ModelRelease get active => _read('active_model') ?? bundled;
  ModelRelease? get previous => _read('previous_model');

  /// ETag of the last `/model-releases/latest` answer (for If-None-Match).
  String? get etag => _box.get('model_etag') as String?;
  set etag(String? v) => _box.put('model_etag', v);

  DateTime get checkedAt =>
      DateTime.tryParse(
        (_box.get('model_checked_at') as String?) ?? '',
      )?.toLocal() ??
      bundled.date;
  set checkedAt(DateTime v) =>
      _box.put('model_checked_at', v.toUtc().toIso8601String());

  File fileFor(String version) =>
      File('${_dir.path}/crop_disease_$version.tflite');

  Future<Uint8List> bytesOf(ModelRelease r) async =>
      r.version == bundled.version && r.sha256 == bundled.sha256
      ? _bundledBytes
      : fileFor(r.version).readAsBytes();

  /// Makes [next] active and keeps the current one as previous.
  Future<void> activate(ModelRelease next) async {
    await _write('previous_model', active);
    await _write('active_model', next);
  }

  /// Swaps back to the previous model (and forgets it).
  Future<void> rollbackTo(ModelRelease prev) async {
    await _write('active_model', prev);
    await _box.delete('previous_model');
  }

  ModelRelease? _read(String key) {
    final m = _box.get(key);
    if (m is! Map) return null;
    return ModelRelease(
      version: m['version'] as String,
      sizeBytes: m['size_bytes'] as int,
      sha256: m['sha256'] as String,
      classLabels: List<String>.from(m['class_labels'] as List),
      threshold: (m['threshold'] as num).toDouble(),
      date: DateTime.parse(m['date'] as String).toLocal(),
    );
  }

  Future<void> _write(String key, ModelRelease r) => _box.put(key, {
    'version': r.version,
    'size_bytes': r.sizeBytes,
    'sha256': r.sha256,
    'class_labels': r.classLabels,
    'threshold': r.threshold,
    'date': r.date.toUtc().toIso8601String(),
  });
}
