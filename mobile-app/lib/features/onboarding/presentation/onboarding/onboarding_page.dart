import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leafcheck/app/router/routes.dart';
import 'package:leafcheck/features/onboarding/presentation/onboarding/widgets/onboarding_parts.dart';
import 'package:leafcheck/features/onboarding/presentation/strings/onboarding_strings.dart';
import 'package:leafcheck/features/settings/presentation/settings/app_settings_controller.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';

/// S8 Onboarding (s8_a…c): three pages, shown until completed once.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;
  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
    if (mounted) context.go(Routes.scan);
  }

  Future<void> _next() async {
    if (_index == _count - 1) return _finish();
    // animateTo asserts on a zero duration, so jump when motion is reduced.
    if (ReduceMotion.of(context)) {
      _pages.jumpToPage(_index + 1);
    } else {
      await _pages.nextPage(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _count - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: AppSize.minTouch,
              child: Align(
                alignment: Alignment.centerRight,
                child: last
                    ? null
                    : AppTextButton(
                        label: OnboardingStrings.skip,
                        onPressed: _finish,
                      ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  OnboardingStep(
                    visual: FieldPhoto(),
                    title: OnboardingStrings.offlineTitle,
                    body: OnboardingStrings.offlineBody,
                  ),
                  OnboardingStep(
                    visual: PhotoCompare(),
                    title: OnboardingStrings.photoTitle,
                    body: OnboardingStrings.photoBody,
                  ),
                  OnboardingStep(
                    visual: PrivacyPoints(),
                    title: OnboardingStrings.privacyTitle,
                    body: OnboardingStrings.privacyBody,
                  ),
                ],
              ),
            ),
            PageDots(index: _index, count: _count),
            Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: PrimaryButton(
                label: last ? OnboardingStrings.start : OnboardingStrings.next,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
