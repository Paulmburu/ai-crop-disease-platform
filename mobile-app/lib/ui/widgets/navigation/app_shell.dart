import 'package:flutter/material.dart';
import 'package:leafcheck/ui/strings/common_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';

/// Bottom navigation with exactly three destinations: Scan, History, Settings.
/// The router passes the tab body and the selected index.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.index,
    required this.onSelect,
    required this.body,
    super.key,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: body,
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onSelect,
      destinations: const [
        NavigationDestination(
          icon: Icon(AppIcons.scan),
          selectedIcon: Icon(AppIcons.scanActive),
          label: CommonStrings.navScan,
        ),
        NavigationDestination(
          icon: Icon(AppIcons.history),
          label: CommonStrings.navHistory,
        ),
        NavigationDestination(
          icon: Icon(AppIcons.settings),
          selectedIcon: Icon(AppIcons.settingsActive),
          label: CommonStrings.navSettings,
        ),
      ],
    ),
  );
}
