import 'package:flutter/material.dart';
import 'app_shell_drawer_header.dart';
import 'app_shell_drawer_pages.dart';
import 'app_shell_drawer_section_title.dart';
import 'app_shell_logout_button.dart';

class AppShellDrawer extends StatelessWidget {
  const AppShellDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    child: const SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShellDrawerHeader(),
          SizedBox(height: 8),
          AppShellDrawerSectionTitle(),
          SizedBox(height: 10),
          Expanded(child: AppShellDrawerPages()),
          AppShellLogoutButton(),
        ],
      ),
    ),
  );
}
