import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/analyzing/analyzing_controller.dart';
import 'package:leafcheck/features/diagnosis/presentation/analyzing/widgets/analyzing_caption.dart';
import 'package:leafcheck/features/diagnosis/presentation/analyzing/widgets/scan_line_overlay.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';
import 'package:leafcheck/ui/widgets/feedback/banners.dart';

/// S2 Analyzing (designs s2_a / s2_b). Replaces itself with the Result.
class AnalyzingPage extends ConsumerWidget {
  const AnalyzingPage({required this.imagePath, this.scanProgress, super.key});

  final String imagePath;

  /// Freezes the scan line (golden key frames only).
  final double? scanProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Result<Diagnosis>>>(analyzeProvider(imagePath), (
      _,
      next,
    ) {
      if (scanProgress != null) return; // frozen key frame: stay put
      if (next case AsyncData(value: Ok(:final value))) {
        context.pushReplacement(Routes.diagnosis(value.id));
      }
    });
    final failed = switch (ref.watch(analyzeProvider(imagePath))) {
      AsyncData(value: Err()) || AsyncError() => true,
      _ => false,
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: DiagnosisStrings.close,
          icon: const Icon(AppIcons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        children: [
          const SizedBox(height: AppSpace.xl),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LeafPhoto(
                  image: AssetImage(imagePath),
                  heroTag: LeafPhoto.scanHeroTag,
                ),
                if (!failed)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: ScanLineOverlay(progress: scanProgress),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          if (failed)
            ErrorBanner(
              title: DiagnosisStrings.analyzeFailed,
              message: '',
              action: AppTextButton(
                label: CommonStrings.tryAgain,
                onPressed: () => ref.invalidate(analyzeProvider(imagePath)),
              ),
            )
          else
            const AnalyzingCaption(),
        ],
      ),
    );
  }
}
