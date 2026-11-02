import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/constants/app_constants.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/history_providers.dart';
import 'package:leafcheck/features/settings/presentation/shared/backend_status_provider.dart';

/// Everything Scan shows (S1-A online, S1-B offline, S1-C first run).
class ScanState {
  const ScanState({
    required this.online,
    required this.modelVersion,
    required this.recent,
  });

  final bool online;
  final String modelVersion;
  final List<Diagnosis> recent;

  bool get firstRun => recent.isEmpty;
}

final scanStateProvider = Provider<AsyncValue<ScanState>>((ref) {
  final history = ref.watch(historyProvider);
  final status = ref.watch(backendStatusProvider);
  final model = ref.watch(activeModelProvider);
  return history.whenData(
    (all) => ScanState(
      // Unknown status counts as online so the banner never flashes on start.
      online: status.value?.online ?? true,
      modelVersion: model.version,
      recent: all.take(AppConstants.recentCount).toList(),
    ),
  );
});

/// Retry from the offline banner.
Future<void> retryConnection(WidgetRef ref) =>
    ref.read(watchBackendStatusProvider).refresh();
