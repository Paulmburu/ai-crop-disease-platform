import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/utils/clock.dart';
import 'package:leafcheck/features/advice/infrastructure/http/http_advice_repository.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/http/http_server_classifier.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/http/http_sync_service.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/litert/litert_classifier.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/local/hive_diagnosis_repository.dart';
import 'package:leafcheck/features/model_update/infrastructure/http/http_model_update_repository.dart';
import 'package:leafcheck/features/model_update/infrastructure/model_store.dart';
import 'package:leafcheck/features/settings/infrastructure/http_backend_status_source.dart';
import 'package:leafcheck/features/settings/infrastructure/local/hive_settings_repository.dart';
import 'package:leafcheck/shared/http/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Binds every port to its real adapter: LiteRT on the phone, Hive on disk,
/// go-backend over HTTP ([BackendConfig.serverUrl]).
Future<List<Override>> realOverrides() async {
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox<dynamic>('settings');
  final diagnosesBox = await Hive.openBox<dynamic>('diagnoses');
  final docs = await getApplicationDocumentsDirectory();
  final store = await ModelStore.open(
    settingsBox,
    Directory('${docs.path}/models'),
  );
  final api = ApiClient(
    baseUrl: BackendConfig.serverUrl,
    apiKey: BackendConfig.apiKey,
  );
  final repo = HiveDiagnosisRepository(
    diagnosesBox,
    Directory('${docs.path}/photos'),
  );
  final classifier = LiteRtClassifier(store);
  return [
    idGeneratorProvider.overrideWithValue(() => const Uuid().v4()),
    diagnosisRepositoryProvider.overrideWithValue(repo),
    classifierProvider.overrideWithValue(classifier),
    serverClassifierProvider.overrideWithValue(HttpServerClassifier(api)),
    syncServiceProvider.overrideWithValue(
      HttpSyncService(api, repo, clock: systemClock),
    ),
    adviceRepositoryProvider.overrideWithValue(HttpAdviceRepository(api)),
    modelUpdateRepositoryProvider.overrideWithValue(
      HttpModelUpdateRepository(api, store, clock: systemClock),
    ),
    settingsRepositoryProvider.overrideWithValue(
      HiveSettingsRepository(
        settingsBox,
        serverUrl: BackendConfig.serverUrl,
        hasAccessKey: BackendConfig.apiKey.isNotEmpty,
      ),
    ),
    backendStatusSourceProvider.overrideWithValue(
      HttpBackendStatusSource(api, clock: systemClock),
    ),
    benchmarkProvider.overrideWithValue(classifier),
  ];
}
