import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';

/// Status dot + service name + value ("OK · 24 ms" / "Down").
class ServiceRow extends StatelessWidget {
  const ServiceRow({
    required this.name,
    required this.value,
    required this.ok,
    super.key,
  });

  final String name;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = ok ? c.primary : c.error;
    return Semantics(
      label: '$name: $value',
      excludeSemantics: true,
      child: SizedBox(
        height: AppSize.minTouch,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(child: Text(name, style: t.bodyLarge)),
            Text(
              value,
              style: t.bodyMedium.numeric.copyWith(
                color: ok ? c.onSurfaceVariant : c.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
