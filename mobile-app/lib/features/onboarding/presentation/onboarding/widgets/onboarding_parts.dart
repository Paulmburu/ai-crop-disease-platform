import 'package:flutter/material.dart';
import 'package:leafcheck/features/onboarding/presentation/strings/onboarding_strings.dart';
import 'package:leafcheck/ui/assets/app_assets.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/chips/status_chip.dart';
import 'package:leafcheck/ui/widgets/diagnosis/leaf_photo.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// Visual (top) + title + body: the shared layout of every page.
class OnboardingStep extends StatelessWidget {
  const OnboardingStep({
    required this.visual,
    required this.title,
    required this.body,
    super.key,
  });

  final Widget visual;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      children: [
        SizedBox(height: 380, child: visual),
        const SizedBox(height: AppSpace.xxl),
        Text(title, style: t.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Text(
          body,
          style: t.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// S8-A visual.
class FieldPhoto extends StatelessWidget {
  const FieldPhoto({super.key});
  @override
  Widget build(BuildContext context) =>
      const LeafPhoto(image: AssetImage(AppAssets.fieldRows));
}

/// S8-B visual: good vs hard-to-read photo.
class PhotoCompare extends StatelessWidget {
  const PhotoCompare({super.key});

  Widget _side(String asset, Widget chip) => Expanded(
    child: Stack(
      fit: StackFit.expand,
      children: [
        LeafPhoto(image: AssetImage(asset)),
        Positioned(left: AppSpace.sm, bottom: AppSpace.sm, child: chip),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _side(
        AppAssets.leafHealthy,
        const StatusChip(
          label: OnboardingStrings.good,
          tone: ChipTone.positive,
          icon: AppIcons.check,
        ),
      ),
      const SizedBox(width: AppSpace.md),
      _side(
        AppAssets.leafBlurry,
        const StatusChip(
          label: OnboardingStrings.hardToRead,
          tone: ChipTone.error,
          icon: AppIcons.close,
        ),
      ),
    ],
  );
}

/// S8-C visual: three privacy points on a card.
class PrivacyPoints extends StatelessWidget {
  const PrivacyPoints({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).colorScheme.primary;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTextRow(
            icon: AppIcons.camera,
            iconColor: p,
            text: OnboardingStrings.privacyPhotos,
          ),
          const SizedBox(height: AppSpace.md),
          IconTextRow(
            icon: AppIcons.upload,
            iconColor: p,
            text: OnboardingStrings.privacySync,
          ),
          const SizedBox(height: AppSpace.md),
          IconTextRow(
            icon: Icons.person_off_outlined,
            iconColor: p,
            text: OnboardingStrings.privacyAccount,
          ),
        ],
      ),
    );
  }
}

/// Page indicator: the active dot is a 24 x 8 pill.
class PageDots extends StatelessWidget {
  const PageDots({required this.index, required this.count, super.key});
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
      label: OnboardingStrings.page(index + 1, count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: ReduceMotion.duration(context, AppMotion.medium),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? c.primary : c.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
        ],
      ),
    );
  }
}
