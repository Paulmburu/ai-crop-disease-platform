import 'package:flutter/material.dart';
import 'package:leafcheck/core/enums/sync_state.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/widgets/chips/status_chip.dart';

/// Sync badge for a diagnosis; cross-fades when the state changes.
class SyncChip extends StatelessWidget {
  const SyncChip(this.state, {super.key});
  final SyncState state;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: ReduceMotion.duration(context, AppMotion.medium),
    child: switch (state) {
      SyncState.pending => const StatusChip(
        key: ValueKey(SyncState.pending),
        label: CommonStrings.pending,
        tone: ChipTone.warning,
        icon: AppIcons.pending,
      ),
      SyncState.syncing => const StatusChip(
        key: ValueKey(SyncState.syncing),
        label: CommonStrings.syncing,
        tone: ChipTone.warning,
        busy: true,
      ),
      SyncState.synced => const StatusChip(
        key: ValueKey(SyncState.synced),
        label: CommonStrings.synced,
        tone: ChipTone.positive,
        icon: AppIcons.online,
      ),
      SyncState.rejected => const StatusChip(
        key: ValueKey(SyncState.rejected),
        label: CommonStrings.rejected,
        tone: ChipTone.error,
        icon: AppIcons.error,
      ),
    },
  );
}
