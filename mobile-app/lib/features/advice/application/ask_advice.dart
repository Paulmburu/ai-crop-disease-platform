import 'package:leafcheck/core/constants/app_constants.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/advice/domain/advice.dart';

/// Validates the question (same limits as the server), then asks.
class AskAdvice {
  const AskAdvice(this.repository);
  final AdviceRepository repository;

  Future<Result<AdviceAnswer>> call(String question, String classLabel) {
    final q = question.trim();
    if (q.length < AppConstants.minQuestionLength ||
        q.length > AppConstants.maxQuestionLength) {
      return Future.value(
        const Err(
          Invalid(
            code: 'invalid_question',
            detail: 'Questions must be 3 to 500 characters.',
          ),
        ),
      );
    }
    return repository.ask(q, classLabel);
  }
}
