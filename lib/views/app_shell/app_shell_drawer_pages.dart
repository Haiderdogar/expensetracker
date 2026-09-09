import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../app_shell_drawer_item.dart';
import '../notes/notes_screen.dart';
import '../profile/profile_view_screen.dart';
import '../settings/settings_screen.dart';
import 'app_shell_providers.dart';

class AppShellDrawerPages extends ConsumerWidget {
  const AppShellDrawerPages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openProfile() async {
      Navigator.of(context).pop();
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileViewScreen()));
      ref.invalidate(appShellProfileProvider);
    }
    void openPage(Widget page) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
      DrawerItem(icon: Icons.person_outline_rounded, label: AppStrings.profile, onTap: openProfile),
      const SizedBox(height: 6),
      DrawerItem(icon: Icons.note_alt_outlined, label: AppStrings.notes, onTap: () => openPage(const NotesScreen())),
      const SizedBox(height: 6),
      DrawerItem(icon: Icons.settings_outlined, label: AppStrings.settings, onTap: () => openPage(const SettingsScreen())),
    ]);
  }
}
