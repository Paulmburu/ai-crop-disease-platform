import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/library/domain/disease_note.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';

final diseaseNotesProvider = FutureProvider<List<DiseaseNote>>(
  (ref) => ref.watch(getDiseaseNotesProvider)(),
);

extension DiseaseNoteX on DiseaseNote {
  DiagnosisCondition get condition => DiagnosisCondition.fromLabel(classLabel);

  /// First sentence of the overview, for the list cards.
  String get summary {
    final o = section('Overview') ?? '';
    final end = o.indexOf('. ');
    return end < 0 ? o : o.substring(0, end + 1);
  }

  String get photo => switch (condition) {
    DiagnosisCondition.lateBlight => AppAssets.leafLateBlight,
    DiagnosisCondition.earlyBlight => AppAssets.leafEarlyBlight,
    DiagnosisCondition.healthy => AppAssets.leafHealthy,
  };
}
