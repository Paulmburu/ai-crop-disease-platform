import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/theme/typography.dart';

/// Card: surface-container-low, radius 16, 16 dp padding, no shadow.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.color,
    this.bordered = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: bordered ? Border.all(color: c.outlineVariant) : null,
      ),
      child: child,
    );
  }
}

/// Label on the left (secondary), value on the right (tabular figures).
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.leading,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpace.md),
          ],
          Expanded(
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Text(
            value,
            textAlign: TextAlign.end,
            style: t.bodyMedium.numeric.copyWith(
              color: valueColor ?? c.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title on the left and an optional action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSize.minTouch,
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    ),
  );
}

/// 24 dp outlined icon + body text (tips, privacy points).
class IconTextRow extends StatelessWidget {
  const IconTextRow({
    required this.icon,
    required this.text,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? c.onSurfaceVariant),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Opens a modal sheet with the theme's shape, handle and 32% scrim.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool expand = false,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: expand,
    useSafeArea: true,
    useRootNavigator: true, // cover the bottom nav like the designs
    builder: builder,
  );
}
