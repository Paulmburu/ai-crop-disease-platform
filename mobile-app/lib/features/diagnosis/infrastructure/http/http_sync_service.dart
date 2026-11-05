import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/repositories/ports.dart';
import 'package:leafcheck/shared/http/api_client.dart';

/// Uploads the outbox with `POST /api/v1/diagnoses:sync` (≤ 500 per call).
/// Safe to repeat: the server answers `duplicate` for ids it already has.
class HttpSyncService implements SyncService {
  HttpSyncService(this.api, this.repository, {required Clock clock})
    : _clock = clock;

  final ApiClient api;
  final DiagnosisRepository repository;
  final Clock _clock;
  DateTime? _lastSync;
  bool _running = false;

  @override
  DateTime? get lastSyncAt => _lastSync;

  @override
  Future<Result<int>> syncPending() async {
    if (_running) return const Ok(0); // auto + manual sync at the same time
    _running = true;
    try {
      final pending = (await repository.watchAll().first)
          .where(
            (d) =>
                d.syncState == SyncState.pending ||
                d.syncState == SyncState.syncing, // interrupted last time
          )
          .take(500)
          .toList();
      if (pending.isEmpty) {
        _lastSync = _clock();
        return const Ok(0);
      }
      for (final d in pending) {
        await repository.save(d.copyWith(syncState: SyncState.syncing));
      }
      final r = await api.guard(
        () => api.dio.post<Map<String, dynamic>>(
          '/api/v1/diagnoses:sync',
          data: {
            'items': [for (final d in pending) _toJson(d)],
          },
        ),
      );
      switch (r) {
        case Err(:final failure):
          for (final d in pending) {
            await repository.save(d.copyWith(syncState: SyncState.pending));
          }
          return Err(failure);
        case Ok(:final value):
          final items = (value.data!['items'] as List)
              .cast<Map<String, dynamic>>();
          var synced = 0;
          for (final (i, d) in pending.indexed) {
            final item = items[i]; // same order as the request
            if (item['outcome'] == 'invalid') {
              final err = item['error'] as Map<String, dynamic>?;
              await repository.save(
                d.copyWith(
                  syncState: SyncState.rejected,
                  rejectReason: err?['detail'] as String? ?? 'Rejected',
                ),
              );
            } else {
              synced++;
              await repository.save(d.copyWith(syncState: SyncState.synced));
            }
          }
          _lastSync = _clock();
          return Ok(synced);
      }
    } finally {
      _running = false;
    }
  }

  static Map<String, Object?> _toJson(Diagnosis d) => {
    'id': d.id,
    'device_id': d.deviceId,
    'class_label': d.condition.label,
    'confidence': d.confidence,
    'confidence_threshold': d.prediction.threshold,
    'model_version': d.prediction.modelVersion,
    'captured_at': d.capturedAt.toUtc().toIso8601String(),
  };
}
