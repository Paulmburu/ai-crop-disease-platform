import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/diagnosis_colors.dart';

/// Visual tone of a diagnosis. Features map their domain condition to a tone,
/// so `ui/` never depends on feature code.
enum DiagnosisTone { healthy, earlyBlight, lateBlight, uncertain }

extension DiagnosisToneX on DiagnosisTone {
  IconData get icon => switch (this) {
    DiagnosisTone.healthy => AppIcons.healthy,
    DiagnosisTone.earlyBlight => AppIcons.earlyBlight,
    DiagnosisTone.lateBlight => AppIcons.lateBlight,
    DiagnosisTone.uncertain => AppIcons.uncertain,
  };

  StatusColors colors(BuildContext context) {
    final d = context.diagnosisColors;
    return switch (this) {
      DiagnosisTone.healthy => d.healthy,
      DiagnosisTone.earlyBlight => d.earlyBlight,
      DiagnosisTone.lateBlight => d.lateBlight,
      DiagnosisTone.uncertain => d.uncertain,
    };
  }
}
