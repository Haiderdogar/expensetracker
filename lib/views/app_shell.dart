import 'package:flutter/material.dart';

import '../core/utils/global_keys.dart';
import 'app_shell/app_shell_bottom_navigation.dart';
import 'app_shell/app_shell_drawer.dart';
import 'app_shell/app_shell_navigation_body.dart';

/// The application chrome. State is owned by its focused child widgets.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    key: appShellScaffoldKey,
    drawer: AppShellDrawer(),
    body: AppShellNavigationBody(),
    extendBody: true,
    bottomNavigationBar: AppShellBottomNavigation(),
  );
}
