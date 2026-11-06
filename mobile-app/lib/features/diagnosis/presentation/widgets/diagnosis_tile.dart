import 'package:flutter/material.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_presenter.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/sync_chip.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';

/// 72 dp list row used by Scan (recent) and History.
class DiagnosisTile extends StatelessWidget {
  const DiagnosisTile({
    required this.diagnosis,
    required this.when,
    required this.onTap,
    this.showSource = false,
    super.key,
  });

  final Diagnosis diagnosis;

  /// Already formatted ("Today, 09:12" on Scan, "09:12" in History).
  final String when;
  final VoidCallback onTap;

  /// History adds "· On-device" / "· Server".
  final bool showSource;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final pct = Formatters.percent(diagnosis.confidence);
    final subtitle = showSource
        ? '${DiagnosisStrings.tileSubtitle(when, pct)} · '
              '${sourceLabel(diagnosis)}'
        : DiagnosisStrings.tileSubtitle(when, pct);
    return Semantics(
      button: true,
      label: '${diagnosis.title}, $subtitle',
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppSize.listTile,
          child: Row(
            children: [
              LeafPhoto(
                image: AppAssets.photo(diagnosis.imagePath),
                width: AppSize.thumbnail,
                height: AppSize.thumbnail,
                radius: AppRadius.thumbnail,
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DiagnosisIcon(diagnosis.tone),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            diagnosis.title,
                            style: t.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: t.bodyMedium.numeric.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              SyncChip(diagnosis.syncState),
            ],
          ),
        ),
      ),
    );
  }

  static String sourceLabel(Diagnosis d) => switch (d.prediction.source) {
    PredictionSource.server => CommonStrings.server,
    PredictionSource.onDevice => CommonStrings.onDevice,
  };
}
