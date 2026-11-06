import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/model_update/domain/model_release.dart';
import 'package:leafcheck/features/model_update/infrastructure/model_store.dart';
import 'package:leafcheck/shared/http/api_client.dart';

/// Model updates from go-backend: `latest` with ETag/304, artifact download
/// with progress, sha256 checked before switching, previous model kept.
class HttpModelUpdateRepository implements ModelUpdateRepository {
  HttpModelUpdateRepository(this.api, this.store, {required Clock clock})
    : _clock = clock;

  final ApiClient api;
  final ModelStore store;
  final Clock _clock;
  final _artifactUrls = <String, String>{};

  @override
  ModelRelease get active => store.active;
  @override
  ModelRelease? get previous => store.previous;
  @override
  DateTime get checkedAt => store.checkedAt;

  @override
  Future<Result<ModelRelease?>> check() async {
    final r = await api.guard(
      () => api.dio.get<Map<String, dynamic>>(
        '/api/v1/model-releases/latest',
        options: Options(
          headers: {if (store.etag != null) 'If-None-Match': store.etag},
          validateStatus: (c) => c == 200 || c == 304 || c == 404,
        ),
      ),
    );
    switch (r) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final res):
        store.checkedAt = _clock();
        if (res.statusCode != 200) return const Ok(null); // 304 or no release
        store.etag = res.headers.value('etag');
        final j = res.data!;
        final latest = ModelRelease(
          version: j['version'] as String,
          sizeBytes: j['size_bytes'] as int,
          sha256: j['sha256'] as String,
          classLabels: List<String>.from(j['class_labels'] as List),
          threshold: (j['confidence_threshold'] as num).toDouble(),
          date: DateTime.parse(j['published_at'] as String).toLocal(),
        );
        _artifactUrls[latest.version] = j['artifact_url'] as String;
        return Ok(latest.sha256 == active.sha256 ? null : latest);
    }
  }

  // ponytail: restarts from zero after a dropped connection; resume with a
  // Range header from the .part length if field downloads prove flaky.
  @override
  Stream<DownloadProgress> download(ModelRelease release) {
    final out = StreamController<DownloadProgress>();
    final part = File('${store.fileFor(release.version).path}.part');
    final url =
        _artifactUrls[release.version] ??
        '/api/v1/model-releases/${release.version}/artifact';
    unawaited(
      api.dio
          .download(
            url,
            part.path,
            onReceiveProgress: (got, total) => out.add(
              DownloadProgress(got, total > 0 ? total : release.sizeBytes),
            ),
          )
          // A failed or partial download simply ends the stream: activate()
          // then refuses the incomplete file on its sha256.
          .then((_) => out.close(), onError: (Object _) => out.close()),
    );
    return out.stream;
  }

  @override
  Future<Result<ModelRelease>> activate(ModelRelease release) async {
    final part = File('${store.fileFor(release.version).path}.part');
    if (!part.existsSync()) return const Err(ChecksumMismatch());
    final digest = sha256.convert(await part.readAsBytes()).toString();
    if (digest != release.sha256) {
      await part.delete();
      return const Err(ChecksumMismatch()); // keep the current model
    }
    await part.rename(store.fileFor(release.version).path);
    final installed = ModelRelease(
      version: release.version,
      sizeBytes: release.sizeBytes,
      sha256: release.sha256,
      classLabels: release.classLabels,
      threshold: release.threshold,
      date: _clock(),
    );
    await store.activate(installed);
    return Ok(installed);
  }

  @override
  Future<Result<ModelRelease>> rollback() async {
    final prev = store.previous;
    if (prev == null) {
      return const Err(Invalid(code: 'no_previous', detail: 'No backup model'));
    }
    await store.rollbackTo(prev);
    return Ok(prev);
  }
}
