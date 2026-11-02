import 'package:flutter/material.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/diagnosis_tone.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/chips/status_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/confidence_bar.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';
import 'package:leafcheck/ui/widgets/feedback/banners.dart';
import 'package:leafcheck/ui/widgets/feedback/empty_state.dart';
import 'package:leafcheck/ui/widgets/feedback/skeleton_lines.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';
import 'package:leafcheck/ui/widgets/progress/progress_ring.dart';

/// Debug-only catalogue of the shared widgets, laid out like
/// `designs/c0_component_reference`. Not shipped in release navigation.
class ComponentsPage extends StatelessWidget {
  const ComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.sm),
      child: Text(s, style: t.labelMedium),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Components')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        children: [
          label('Buttons'),
          PrimaryButton(
            label: CommonStrings.scanLeaf,
            icon: AppIcons.camera,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpace.md),
          TonalButton(label: CommonStrings.getAdvice, onPressed: () {}),
          AppTextButton(label: CommonStrings.retry, onPressed: () {}),
          label('Status chips'),
          const Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              StatusChip(
                label: 'Model v1',
                tone: ChipTone.neutral,
                icon: AppIcons.model,
              ),
              StatusChip(
                label: CommonStrings.online,
                tone: ChipTone.positive,
                icon: AppIcons.online,
              ),
              StatusChip(
                label: CommonStrings.pending,
                tone: ChipTone.warning,
                icon: AppIcons.pending,
              ),
              StatusChip(
                label: CommonStrings.rejected,
                tone: ChipTone.error,
                icon: AppIcons.error,
              ),
              StatusChip(
                label: CommonStrings.syncing,
                tone: ChipTone.warning,
                busy: true,
              ),
            ],
          ),
          label('Diagnosis headers'),
          for (final (tone, text) in const [
            (DiagnosisTone.healthy, 'Healthy'),
            (DiagnosisTone.earlyBlight, 'Early blight'),
            (DiagnosisTone.lateBlight, 'Late blight'),
            (DiagnosisTone.uncertain, 'Not sure'),
          ]) ...[
            DiagnosisChip(tone: tone, label: text, large: true),
            const SizedBox(height: AppSpace.sm),
          ],
          label('Confidence bar'),
          SectionCard(
            bordered: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Confidence', style: t.titleMedium)),
                    Text('76.5%', style: t.titleMedium.numeric),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Builder(
                  builder: (c) => ConfidenceBar(
                    value: 0.765,
                    threshold: 0.5,
                    color: DiagnosisTone.lateBlight.colors(c).bar,
                  ),
                ),
              ],
            ),
          ),
          label('Leaf photo'),
          const LeafPhoto(
            image: AssetImage(AppAssets.leafLateBlight),
            height: 120,
            width: double.infinity,
          ),
          label('Offline banner'),
          OfflineBanner(visible: true, onRetry: () {}),
          label('Error banner'),
          ErrorBanner(
            title: "Couldn't sync this diagnosis",
            message: 'The phone clock was ahead by more than a day.',
            action: AppTextButton(
              label: CommonStrings.tryAgain,
              onPressed: () {},
            ),
          ),
          label('Card + info rows'),
          const SectionCard(
            child: Column(
              children: [
                InfoRow(label: 'Size', value: '9.0 MB'),
                InfoRow(label: 'Installed', value: '29 Oct 2026'),
              ],
            ),
          ),
          label('Section header + icon rows'),
          SectionHeader(
            title: 'Recent',
            action: AppTextButton(
              label: CommonStrings.seeAll,
              onPressed: () {},
            ),
          ),
          const IconTextRow(
            icon: AppIcons.sun,
            text: 'Use daylight, avoid strong shadows',
          ),
          label('Progress'),
          const LinearProgressIndicator(value: 0.42),
          const SizedBox(height: AppSpace.md),
          const Row(
            children: [
              ProgressRing(value: 0.42),
              SizedBox(width: AppSpace.lg),
              ProgressRing(value: 1),
            ],
          ),
          label('Skeleton'),
          const SkeletonLines(widths: [1, 0.92, 0.6]),
          label('Empty state'),
          SectionCard(
            child: EmptyState(
              icon: AppIcons.history,
              title: 'No diagnoses yet',
              message: 'Scan a leaf to see it here.',
              actions: [
                TonalButton(
                  label: CommonStrings.scanLeaf,
                  onPressed: () {},
                  expand: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
        ],
      ),
    );
  }
}
