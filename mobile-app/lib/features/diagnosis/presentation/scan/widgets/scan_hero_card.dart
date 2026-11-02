import 'dart:async';

import 'package:flutter/material.dart';
import 'package:leafcheck/features/diagnosis/presentation/strings/diagnosis_strings.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/buttons/buttons.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// The main call to action (S1). The camera circle pulses softly
/// (1.00 → 1.04, 2400 ms); still when motion is reduced.
class ScanHeroCard extends StatelessWidget {
  const ScanHeroCard({required this.onScan, super.key});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xxl,
        AppSpace.lg,
        AppSpace.xl,
      ),
      child: Column(
        children: [
          _Pulse(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.camera,
                size: 36,
                color: c.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            DiagnosisStrings.heroTitle,
            style: t.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            DiagnosisStrings.heroBody,
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.xl),
          PrimaryButton(
            label: CommonStrings.scanLeaf,
            icon: AppIcons.camera,
            onPressed: onScan,
          ),
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppMotion.pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReduceMotion.of(context)) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_c.isAnimating) {
      unawaited(_c.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween<double>(
      begin: 1,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _c, curve: AppMotion.standard)),
    child: widget.child,
  );
}
