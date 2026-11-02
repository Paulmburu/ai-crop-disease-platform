import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/history_providers.dart';

/// The diagnosis shown on Result, kept live (sync state, second opinion).
final resultProvider = Provider.autoDispose
    .family<AsyncValue<Diagnosis?>, String>(
      (ref, id) => ref
          .watch(historyProvider)
          .whenData((all) => all.where((d) => d.id == id).firstOrNull),
    );

/// Second-opinion request state for one diagnosis (S3-E).
class SecondOpinionController extends Notifier<AsyncValue<void>> {
  SecondOpinionController(this.id);
  final String id;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns the failure to show, if any.
  Future<Failure?> request(Diagnosis d) async {
    state = const AsyncLoading();
    final r = await ref.read(secondOpinionProvider)(d);
    state = const AsyncData(null);
    return switch (r) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  }
}

final secondOpinionControllerProvider = NotifierProvider.autoDispose
    .family<SecondOpinionController, AsyncValue<void>, String>(
      SecondOpinionController.new,
    );

Future<void> deleteDiagnosis(WidgetRef ref, String id) =>
    ref.read(deleteDiagnosisProvider)(id);
