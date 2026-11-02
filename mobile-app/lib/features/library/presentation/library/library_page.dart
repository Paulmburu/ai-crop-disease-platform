import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_presenter.dart';
import 'package:leafcheck/features/library/domain/disease_note.dart';
import 'package:leafcheck/features/library/presentation/library_providers.dart';
import 'package:leafcheck/features/library/presentation/strings/library_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';

/// S9-A Potato diseases (s9_a_disease_library).
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(diseaseNotesProvider).value ?? const [];
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(LibraryStrings.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.xl,
        ),
        children: [
          Text(
            LibraryStrings.intro,
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.lg),
          for (final n in notes) ...[
            _DiseaseCard(note: n),
            const SizedBox(height: AppSpace.cardGap),
          ],
        ],
      ),
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({required this.note});
  final DiseaseNote note;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final cond = note.condition;
    final name = DiagnosisStrings.name(cond);
    return Material(
      color: c.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.disease(cond.label)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LeafPhoto(
              image: AssetImage(note.photo),
              height: 120,
              width: double.infinity,
              radius: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DiagnosisChip(tone: cond.tone, label: name),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          cond == DiagnosisCondition.healthy
                              ? LibraryStrings.healthyLeaf
                              : name,
                          style: t.titleMedium,
                        ),
                        Text(
                          note.summary,
                          style: t.bodyMedium?.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(AppIcons.chevron),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
