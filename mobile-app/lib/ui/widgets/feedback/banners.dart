import 'package:flutter/material.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// Full-width strip under the app bar. Slides in/out with [visible].
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.visible, this.onRetry, super.key});

  final bool visible;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final content = !visible
        ? const SizedBox(width: double.infinity)
        : Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: AppSize.banner),
            color: c.surfaceContainerHigh,
            padding: const EdgeInsets.only(left: AppSpace.lg),
            child: Row(
              children: [
                Icon(
                  AppIcons.offline,
                  size: AppSize.chipIcon,
                  color: c.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    CommonStrings.offlineBanner,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: const Text(CommonStrings.retry),
                  ),
              ],
            ),
          );
    // AnimatedSize must not run with a zero duration (reduce motion).
    if (ReduceMotion.of(context)) return content;
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: visible ? AppMotion.enter : AppMotion.exit,
      child: content,
    );
  }
}

/// Error-container card with icon, title, body and an optional action.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    required this.title,
    required this.message,
    this.icon = AppIcons.error,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.onErrorContainer),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleMedium?.copyWith(color: c.onErrorContainer),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  message,
                  style: t.bodyMedium?.copyWith(color: c.onErrorContainer),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  // Actions inside an error card use the error text colour.
                  TextButtonTheme(
                    data: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: c.onErrorContainer,
                      ),
                    ),
                    child: action!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
