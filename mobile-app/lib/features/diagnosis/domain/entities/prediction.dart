import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';

/// One class and its probability (0–1).
typedef ClassScore = ({DiagnosisCondition condition, double probability});

/// A model output: scores sorted best first, plus how it was produced.
class Prediction {
  Prediction({
    required List<ClassScore> scores,
    required this.threshold,
    required this.modelVersion,
    required this.latencyMs,
    required this.source,
  }) : scores = List.unmodifiable(
         <ClassScore>[...scores]
           ..sort((a, b) => b.probability.compareTo(a.probability)),
       ) {
    if (scores.isEmpty) throw ArgumentError('scores must not be empty');
    for (final s in scores) {
      if (s.probability < 0 || s.probability > 1) {
        throw ArgumentError.value(s.probability, 'probability', 'not in 0–1');
      }
    }
    if (threshold < 0 || threshold > 1) {
      throw ArgumentError.value(threshold, 'threshold', 'not in 0–1');
    }
  }

  final List<ClassScore> scores;
  final double threshold;
  final String modelVersion;
  final double latencyMs;
  final PredictionSource source;

  ClassScore get top => scores.first;

  DiagnosisStatus get status => top.probability >= threshold
      ? DiagnosisStatus.confident
      : DiagnosisStatus.uncertain;
}
