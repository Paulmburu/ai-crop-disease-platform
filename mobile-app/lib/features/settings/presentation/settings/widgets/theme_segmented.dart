import 'package:flutter/material.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';
import 'package:leafcheck/features/settings/presentation/strings/settings_strings.dart';

/// Light / Dark / System.
class ThemeSegmented extends StatelessWidget {
  const ThemeSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final ThemePreference value;
  final ValueChanged<ThemePreference> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<ThemePreference>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(
        value: ThemePreference.light,
        label: Text(SettingsStrings.light),
      ),
      ButtonSegment(
        value: ThemePreference.dark,
        label: Text(SettingsStrings.dark),
      ),
      ButtonSegment(
        value: ThemePreference.system,
        label: Text(SettingsStrings.system),
      ),
    ],
    selected: {value},
    onSelectionChanged: (s) => onChanged(s.first),
  );
}
