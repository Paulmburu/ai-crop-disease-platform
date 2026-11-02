import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_tile.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// "Recent" header + the last three diagnoses (staggered entrance).
class RecentSection extends StatelessWidget {
  const RecentSection({
    required this.items,
    required this.now,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });

  final List<Diagnosis> items;
  final DateTime now;
  final ValueChanged<Diagnosis> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final reduce = ReduceMotion.of(context);
    return Column(
      children: [
        SectionHeader(
          title: DiagnosisStrings.recent,
          action: AppTextButton(
            label: CommonStrings.seeAll,
            onPressed: onSeeAll,
          ),
        ),
        for (final (i, d) in items.indexed) ...[
          if (i > 0) const Divider(),
          _stagger(
            reduce: reduce,
            index: i,
            child: DiagnosisTile(
              diagnosis: d,
              when: Formatters.relativeDayTime(d.capturedAt, now),
              onTap: () => onOpen(d),
            ),
          ),
        ],
      ],
    );
  }

  /// Fade + small rise, 40 ms apart; nothing when motion is reduced.
  static Widget _stagger({
    required bool reduce,
    required int index,
    required Widget child,
  }) => reduce
      ? child
      : child
            .animate()
            .fadeIn(
              delay: AppMotion.stagger * index,
              duration: AppMotion.medium,
              curve: AppMotion.enter,
            )
            .slideY(begin: 0.1, end: 0, curve: AppMotion.enter);
}
