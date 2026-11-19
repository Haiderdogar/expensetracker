import 'package:flutter/material.dart';

import 'app_shell_bottom_navigation.dart';

/// Keeps the optional Dashboard banner and navigation in Scaffold's measured
/// bottom bar so its content and floating action button share the same inset.
class AppShellBottomBar extends StatelessWidget {
  const AppShellBottomBar({
    super.key,
    this.banner,
    this.navigation = const AppShellBottomNavigation(),
  });

  final Widget? banner;
  final Widget navigation;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [?banner, navigation],
  );
}
