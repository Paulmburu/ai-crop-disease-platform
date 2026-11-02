import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/features/diagnosis/presentation/widgets/diagnosis_presenter.dart';
import 'package:leafcheck/features/library/presentation/library_providers.dart';
import 'package:leafcheck/features/library/presentation/strings/library_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';
import 'package:url_launcher/url_launcher.dart';

/// S9-B disease detail (s9_b_late_blight), rendered from the bundled note.
class DiseaseDetailPage extends ConsumerWidget {
  const DiseaseDetailPage({required this.classLabel, super.key});
  final String classLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(diseaseNotesProvider).value ?? const [];
    final note = notes.where((n) => n.classLabel == classLabel).firstOrNull;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    if (note == null) return const Scaffold();
    final cond = note.condition;
    final pathogen = DiagnosisStrings.pathogen(cond);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: IconButton.filledTonal(
                tooltip: LibraryStrings.back,
                icon: const Icon(AppIcons.back),
                onPressed: () => context.pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: LeafPhoto(image: AssetImage(note.photo), radius: 0),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpace.screen),
            sliver: SliverList.list(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: DiagnosisChip(
                    tone: cond.tone,
                    label: DiagnosisStrings.name(cond),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(note.title, style: t.displaySmall),
                if (pathogen.isNotEmpty)
                  Text(
                    pathogen,
                    style: t.bodyLarge?.copyWith(
                      color: c.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                for (final s in note.sections) ...[
                  const SizedBox(height: AppSpace.xl),
                  Semantics(
                    header: true,
                    child: Text(s.heading, style: t.titleMedium),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  for (final line in s.body.split('\n'))
                    if (line.trim().isNotEmpty) _Paragraph(line.trim()),
                ],
                const SizedBox(height: AppSpace.xl),
                const Divider(),
                for (final url in note.sources)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.source),
                    title: Text(Uri.parse(url).host, style: t.bodyMedium),
                    trailing: const Icon(AppIcons.openExternal),
                    onTap: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A body line; "- " lines become bullets.
class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (!text.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.xs),
        child: Text(text, style: style),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs, left: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(child: Text(text.substring(2), style: style)),
        ],
      ),
    );
  }
}
