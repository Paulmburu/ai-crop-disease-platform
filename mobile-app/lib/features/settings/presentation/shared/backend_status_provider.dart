import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';

/// Latest `/ready` result; drives online/offline UI everywhere.
final backendStatusProvider = StreamProvider<BackendStatus>(
  (ref) => ref.watch(watchBackendStatusProvider)(),
);
