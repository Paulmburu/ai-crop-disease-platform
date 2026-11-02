import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// "2 waiting to sync · Last sync today 08:55" under the app bar.
class SyncSummaryRow extends StatelessWidget {
  const SyncSummaryRow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          Icon(AppIcons.pending, size: 16, color: c.onSurfaceVariant),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: c.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
