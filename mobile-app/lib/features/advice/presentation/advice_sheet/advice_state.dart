import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/advice/domain/advice.dart';
import 'package:leafcheck/features/settings/presentation/shared/backend_status_provider.dart';

enum AdvicePhase { questions, loading, answer, offline, unavailable, invalid }

class AdviceState {
  const AdviceState({
    this.phase = AdvicePhase.questions,
    this.question,
    this.answer,
    this.requestId,
  });

  final AdvicePhase phase;
  final String? question;
  final AdviceAnswer? answer;

  /// For "Reference: …" on the unavailable state.
  final String? requestId;
}

/// One advice conversation per class label, alive while the sheet is open.
class AdviceController extends Notifier<AdviceState> {
  AdviceController(this.classLabel);
  final String classLabel;

  @override
  AdviceState build() {
    final online = ref.read(backendStatusProvider).value?.online ?? true;
    return AdviceState(
      phase: online ? AdvicePhase.questions : AdvicePhase.offline,
    );
  }

  Future<void> ask(String question) async {
    state = AdviceState(phase: AdvicePhase.loading, question: question);
    final r = await ref.read(askAdviceProvider)(question, classLabel);
    state = switch (r) {
      Ok(:final value) => AdviceState(
        phase: AdvicePhase.answer,
        question: question,
        answer: value,
      ),
      Err(failure: Offline()) => AdviceState(
        phase: AdvicePhase.offline,
        question: question,
      ),
      Err(failure: ServerUnavailable(:final requestId)) => AdviceState(
        phase: AdvicePhase.unavailable,
        question: question,
        requestId: requestId,
      ),
      Err(failure: Invalid()) => const AdviceState(phase: AdvicePhase.invalid),
      Err() => AdviceState(phase: AdvicePhase.unavailable, question: question),
    };
  }

  /// Back to the suggested questions (e.g. after "Try again").
  void reset() => state = const AdviceState();
}

final adviceControllerProvider = NotifierProvider.autoDispose
    .family<AdviceController, AdviceState, String>(AdviceController.new);
