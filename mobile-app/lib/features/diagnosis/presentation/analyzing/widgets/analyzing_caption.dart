import 'package:flutter/material.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// "Checking the leaf…" + where it runs + an indeterminate 200 dp bar.
class AnalyzingCaption extends StatelessWidget {
  const AnalyzingCaption({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(DiagnosisStrings.analyzing, style: t.bodyLarge),
          const SizedBox(height: AppSpace.xs),
          Text(
            DiagnosisStrings.analyzingSub,
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.lg),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
