import 'package:flutter/material.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// First run (S1-C): how to take a good photo.
class PhotoTipsCard extends StatelessWidget {
  const PhotoTipsCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DiagnosisStrings.tipsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.sm),
        const IconTextRow(
          icon: AppIcons.sun,
          text: DiagnosisStrings.tipDaylight,
        ),
        const IconTextRow(
          icon: AppIcons.leaf,
          text: DiagnosisStrings.tipOneLeaf,
        ),
        const IconTextRow(
          icon: AppIcons.focus,
          text: DiagnosisStrings.tipSteady,
        ),
      ],
    ),
  );
}
