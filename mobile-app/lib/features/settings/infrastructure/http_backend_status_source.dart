import 'dart:async';

import 'package:dio/dio.dart';
import 'package:leafcheck/core/enums/connectivity_status.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';
import 'package:leafcheck/shared/http/api_client.dart';

/// "Online" = go-backend answered `GET /ready` within 2 s (API_CONTRACT
/// client rule 3), re-checked every [interval] while someone listens.
class HttpBackendStatusSource implements BackendStatusSource {
  HttpBackendStatusSource(
    this.api, {
    required Clock clock,
    this.interval = const Duration(seconds: 10),
  }) : _clock = clock;

  final ApiClient api;
  final Duration interval;
  final Clock _clock;
  late final _changes = StreamController<BackendStatus>.broadcast(
    onListen: () => _timer ??= Timer.periodic(interval, (_) => refresh()),
    onCancel: () {
      _timer?.cancel();
      _timer = null;
    },
  );
  Timer? _timer;
  BackendStatus? _last;

  @override
  Stream<BackendStatus> watch() async* {
    yield _last ?? await refresh();
    yield* _changes.stream;
  }

  @override
  Future<BackendStatus> refresh() async {
    final sw = Stopwatch()..start();
    BackendStatus s;
    try {
      final res = await api.dio.get<Map<String, dynamic>>(
        '/ready',
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
          validateStatus: (code) => code == 200 || code == 503,
        ),
      );
      final j = res.data ?? const <String, dynamic>{};
      bool up(String k) => j[k] == true;
      s = BackendStatus(
        connectivity: ConnectivityStatus.online,
        services: [
          ServiceStatus(
            ServiceName.server,
            ok: true,
            latencyMs: sw.elapsedMilliseconds,
          ),
          ServiceStatus(ServiceName.database, ok: up('database')),
          ServiceStatus(ServiceName.diagnosis, ok: up('ml_service')),
          ServiceStatus(ServiceName.advice, ok: up('rag_service')),
        ],
        checkedAt: _clock(),
      );
    } on Object {
      s = BackendStatus(
        connectivity: ConnectivityStatus.offline,
        services: const [],
        checkedAt: _clock(),
      );
    }
    _last = s;
    if (!_changes.isClosed) _changes.add(s);
    return s;
  }
}
