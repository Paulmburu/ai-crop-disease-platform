import 'package:flutter/material.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';

/// Bottom actions: one filled button + the second-opinion text button.
class ResultActions extends StatelessWidget {
  const ResultActions({
    required this.uncertain,
    required this.onPrimary,
    this.onSecondOpinion,
    this.secondOpinionLoading = false,
    super.key,
  });

  final bool uncertain;
  final VoidCallback onPrimary;

  /// Null hides the button (already shown).
  final VoidCallback? onSecondOpinion;
  final bool secondOpinionLoading;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.sm,
        AppSpace.screen,
        AppSpace.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: uncertain
                ? DiagnosisStrings.retakePhoto
                : CommonStrings.getAdvice,
            icon: uncertain ? AppIcons.camera : AppIcons.advice,
            onPressed: onPrimary,
          ),
          if (onSecondOpinion != null)
            secondOpinionLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpace.md),
                    child: SizedBox.square(
                      dimension: AppSize.icon,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : AppTextButton(
                    label: DiagnosisStrings.askServer,
                    icon: AppIcons.upload,
                    onPressed: onSecondOpinion,
                  ),
        ],
      ),
    ),
  );
}
