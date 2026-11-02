import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/layout/layout.dart';

/// Section label (primary) + a card holding its rows, separated by dividers.
class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.rows, super.key});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xs,
          AppSpace.xl,
          0,
          AppSpace.sm,
        ),
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(
                context,
              ).textButtonTheme.style?.foregroundColor?.resolve({}),
            ),
          ),
        ),
      ),
      SectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, r) in rows.indexed) ...[
              if (i > 0)
                const Divider(indent: AppSpace.lg + AppSize.icon + AppSpace.lg),
              r,
            ],
          ],
        ),
      ),
    ],
  );
}

/// Icon, title, optional subtitle and a trailing control or chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: AppSize.listTile,
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
    leading: Icon(icon),
    title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
    trailing: trailing ?? (onTap == null ? null : const Icon(AppIcons.chevron)),
    onTap: onTap,
  );
}
