import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/application/use_cases.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/history_providers.dart';

/// One day of diagnoses ("Today", "Yesterday", "27 Oct 2026").
typedef DaySection = ({DateTime day, List<Diagnosis> items});

class HistoryState {
  const HistoryState({
    required this.days,
    required this.pending,
    required this.syncingCount,
    this.lastSync,
  });

  final List<DaySection> days;
  final int pending;
  final int syncingCount;
  bool get syncing => syncingCount > 0;
  final DateTime? lastSync;

  bool get isEmpty => days.isEmpty;
}

List<DaySection> groupByDay(List<Diagnosis> all) {
  final map = <DateTime, List<Diagnosis>>{};
  for (final d in all) {
    final t = d.capturedAt;
    map.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(d);
  }
  return [for (final e in map.entries) (day: e.key, items: e.value)];
}

final historyStateProvider = Provider<AsyncValue<HistoryState>>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return ref
      .watch(historyProvider)
      .whenData(
        (all) => HistoryState(
          days: groupByDay(all),
          pending: pendingCount(all),
          syncingCount: all
              .where((d) => d.syncState == SyncState.syncing)
              .length,
          lastSync: sync.lastSyncAt,
        ),
      );
});

/// Pull-to-refresh / sync icon. Returns synced count, or the failure.
Future<Result<int>> syncNow(WidgetRef ref) => ref.read(syncDiagnosesProvider)();

/// "today 08:55" (null when never synced).
String? lastSyncLabel(DateTime? t, DateTime now) =>
    t == null ? null : Formatters.inlineDayTime(t, now);

/// Message for a failed sync.
bool isOffline(Failure f) => f is Offline;
