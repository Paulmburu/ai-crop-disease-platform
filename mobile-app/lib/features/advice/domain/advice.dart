import 'package:leafcheck/core/result/result.dart';

/// One cited source. [n] matches the `[n]` markers in the answer text.
class Citation {
  const Citation({
    required this.n,
    required this.title,
    required this.publisher,
    required this.url,
  });

  final int n;
  final String title;
  final String publisher;
  final String url;
}

class AdviceAnswer {
  const AdviceAnswer({
    required this.text,
    required this.citations,
    required this.grounded,
  });

  /// Plain text with `[n]` citation markers.
  final String text;
  final List<Citation> citations;

  /// False when no guide matched: the answer is a fixed "not enough
  /// information" text.
  final bool grounded;
}

/// go-backend `POST /api/v1/advice` later.
abstract interface class AdviceRepository {
  /// [classLabel] is the model label, e.g. `Potato___Late_blight`.
  Future<Result<AdviceAnswer>> ask(String question, String classLabel);
}
