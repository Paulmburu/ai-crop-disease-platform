import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/theme/diagnosis_tone.dart';

/// Maps the domain to the design system (tone + label). The only place that
/// decides how a diagnosis looks.
extension DiagnosisPresenter on Diagnosis {
  bool get isUncertain => status == DiagnosisStatus.uncertain;

  DiagnosisTone get tone =>
      isUncertain ? DiagnosisTone.uncertain : condition.tone;

  String get title =>
      isUncertain ? DiagnosisStrings.notSure : DiagnosisStrings.name(condition);
}

extension ConditionTone on DiagnosisCondition {
  DiagnosisTone get tone => switch (this) {
    DiagnosisCondition.earlyBlight => DiagnosisTone.earlyBlight,
    DiagnosisCondition.lateBlight => DiagnosisTone.lateBlight,
    DiagnosisCondition.healthy => DiagnosisTone.healthy,
  };
}
