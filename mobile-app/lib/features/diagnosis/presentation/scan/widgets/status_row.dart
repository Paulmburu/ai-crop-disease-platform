import 'package:flutter/material.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/chips/status_chip.dart';

/// "Model v1" + Online/Offline chips under the app bar.
class StatusRow extends StatelessWidget {
  const StatusRow({
    required this.modelVersion,
    required this.online,
    super.key,
  });

  final String modelVersion;
  final bool online;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.sm,
    children: [
      StatusChip(
        label: CommonStrings.model(modelVersion),
        tone: ChipTone.neutral,
        icon: AppIcons.model,
      ),
      if (online)
        const StatusChip(
          label: CommonStrings.online,
          tone: ChipTone.positive,
          icon: AppIcons.online,
        )
      else
        const StatusChip(
          label: CommonStrings.offline,
          tone: ChipTone.neutral,
          icon: AppIcons.offline,
        ),
    ],
  );
}
