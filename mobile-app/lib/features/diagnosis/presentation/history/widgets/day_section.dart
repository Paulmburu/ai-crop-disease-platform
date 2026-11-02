import 'package:flutter/material.dart';
import 'package:leafcheck/core/utils/formatters.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:leafcheck/features/diagnosis/presentation/history/history_state.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_tile.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// Day label + that day's diagnoses ("09:12 · 76.5% · On-device").
class DaySectionView extends StatelessWidget {
  const DaySectionView({
    required this.section,
    required this.now,
    required this.onOpen,
    super.key,
  });

  final DaySection section;
  final DateTime now;
  final ValueChanged<Diagnosis> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.xs),
          child: Semantics(
            header: true,
            child: Text(
              Formatters.relativeDay(section.day, now),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: c.onSurfaceVariant,
              ),
            ),
          ),
        ),
        for (final (i, d) in section.items.indexed) ...[
          if (i > 0) const Divider(),
          DiagnosisTile(
            diagnosis: d,
            when: Formatters.time(d.capturedAt),
            showSource: true,
            onTap: () => onOpen(d),
          ),
        ],
      ],
    );
  }
}
