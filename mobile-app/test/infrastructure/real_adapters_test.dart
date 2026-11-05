import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/advice/infrastructure/http/http_advice_repository.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/http/http_sync_service.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/litert/preprocess.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/local/hive_diagnosis_repository.dart';
import 'package:leafcheck/shared/http/api_client.dart';

/// Answers every request with [handler]'s (status, json body).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final (int, Object?) Function(RequestOptions, Object? body) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(o);
    final (status, body) = handler(o, o.data);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _api(_FakeAdapter a) =>
    ApiClient(baseUrl: 'http://test', apiKey: 'k')..dio.httpClientAdapter = a;

Diagnosis _diagnosis(String id) => Diagnosis(
  id: id,
  deviceId: 'dev',
  prediction: Prediction(
    scores: [
      (condition: DiagnosisCondition.lateBlight, probability: 0.8),
      (condition: DiagnosisCondition.healthy, probability: 0.2),
    ],
    threshold: 0.5,
    modelVersion: 'v1',
    latencyMs: 2,
    source: PredictionSource.onDevice,
  ),
  capturedAt: DateTime.utc(2026, 11, 4, 9),
  imagePath: 'assets/images/leaf_late_blight.jpg',
);

void main() {
  late Directory tmp;
  late Box<dynamic> box;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('leafcheck');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>(
      'd${DateTime.now().microsecondsSinceEpoch}',
    );
  });
  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('preprocess: NHWC 224x224x3 in 0..1', () {
    final x = preprocess(
      File('assets/images/leaf_late_blight.jpg').readAsBytesSync(),
    );
    expect(x.length, 224 * 224 * 3);
    expect(x.every((v) => v >= 0 && v <= 1), isTrue);
    expect(x.any((v) => v > 0.1), isTrue);
  });

  test('Hive repository round-trips a diagnosis', () async {
    final repo = HiveDiagnosisRepository(box, Directory('${tmp.path}/p'));
    await repo.save(
      _diagnosis(
        'a',
      ).copyWith(syncState: SyncState.rejected, rejectReason: 'clock'),
    );
    final back = (await repo.get('a'))!;
    expect(back.condition, DiagnosisCondition.lateBlight);
    expect(back.confidence, 0.8);
    expect(back.syncState, SyncState.rejected);
    expect(back.rejectReason, 'clock');
    expect(back.capturedAt.toUtc(), DateTime.utc(2026, 11, 4, 9));
  });

  test('sync: created/duplicate → synced, invalid → rejected', () async {
    final repo = HiveDiagnosisRepository(box, Directory('${tmp.path}/p'));
    await repo.save(_diagnosis('a'));
    await repo.save(_diagnosis('b'));
    final adapter = _FakeAdapter((o, body) {
      final items = ((body! as Map)['items'] as List)
          .cast<Map<String, dynamic>>();
      return (
        200,
        {
          'items': [
            for (final it in items)
              it['id'] == 'a'
                  ? {'id': 'a', 'outcome': 'duplicate'}
                  : {
                      'id': it['id'],
                      'outcome': 'invalid',
                      'error': {'code': 'x', 'detail': 'clock ahead'},
                    },
          ],
        },
      );
    });
    final r = await HttpSyncService(
      _api(adapter),
      repo,
      clock: DateTime.now,
    ).syncPending();
    expect((r as Ok<int>).value, 1);
    expect((await repo.get('a'))!.syncState, SyncState.synced);
    expect((await repo.get('b'))!.syncState, SyncState.rejected);
    expect((await repo.get('b'))!.rejectReason, 'clock ahead');
    expect(adapter.requests.single.headers['X-API-Key'], 'k');
  });

  test('sync: offline puts items back to pending', () async {
    final repo = HiveDiagnosisRepository(box, Directory('${tmp.path}/p'));
    await repo.save(_diagnosis('a'));
    final api = _api(
      _FakeAdapter(
        (o, _) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'no route',
        ),
      ),
    );
    final r = await HttpSyncService(
      api,
      repo,
      clock: DateTime.now,
    ).syncPending();
    expect((r as Err).failure, isA<Offline>());
    expect((await repo.get('a'))!.syncState, SyncState.pending);
  });

  test('errors map to failures', () async {
    Future<Failure> fail(int status, Map<String, Object?> body) async {
      final api = _api(_FakeAdapter((_, _) => (status, body)));
      final r = await api.guard(() => api.dio.get<Object>('/x'));
      return (r as Err).failure;
    }

    expect(await fail(401, {}), isA<Unauthorized>());
    expect(
      await fail(503, {'error': 'advice_unavailable', 'request_id': 'r'}),
      isA<ServerUnavailable>().having(
        (f) => f.code,
        'code',
        'advice_unavailable',
      ),
    );
    expect(
      await fail(422, {'error': 'validation_error', 'detail': 'bad'}),
      isA<Invalid>().having((f) => f.detail, 'detail', 'bad'),
    );
  });

  test('advice keeps only cited sources', () {
    final a = HttpAdviceRepository.parse({
      'answer': 'Remove leaves [2].',
      'grounded': true,
      'sources': [
        {
          'index': 1,
          'title': 'T',
          'section': 'Symptoms',
          'references': <String>[],
        },
        {
          'index': 2,
          'title': 'Potato late blight',
          'section': 'Management',
          'references': ['https://ipm.ucanr.edu/x'],
        },
      ],
    });
    expect(a.citations.single.n, 2);
    expect(a.citations.single.title, 'Potato late blight: Management');
    expect(a.citations.single.publisher, 'ipm.ucanr.edu');
  });
}
