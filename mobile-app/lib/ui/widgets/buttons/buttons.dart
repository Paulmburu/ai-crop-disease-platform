import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// Filled, 56 dp, radius 16. At most one per screen (DESIGN.md).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onPrimary;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox.square(
              dimension: AppSize.chipIcon,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else if (icon != null)
            Icon(icon, size: AppSize.icon),
          if (loading || icon != null) const SizedBox(width: AppSpace.sm),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Tonal, 48 dp, radius 16 (secondary-container).
class TonalButton extends StatelessWidget {
  const TonalButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Full width (default) or wrap content (e.g. inside an empty state).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      backgroundColor: c.secondaryContainer,
      foregroundColor: c.onSecondaryContainer,
      minimumSize: expand
          ? const Size.fromHeight(AppSize.tonalButton)
          : const Size(AppSize.minTouch, AppSize.tonalButton),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
    );
    final text = Text(label, overflow: TextOverflow.ellipsis);
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: AppSize.chipIcon),
            label: text,
          );
  }
}

/// Text button in primary, 48 dp touch target.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => icon == null
      ? TextButton(onPressed: onPressed, child: Text(label))
      : TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: AppSize.chipIcon),
          label: Text(label),
        );
}
