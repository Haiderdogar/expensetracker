import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../app_shell_drawer_item.dart';
import 'app_shell_providers.dart';

class AppShellDrawerPages extends ConsumerWidget {
  const AppShellDrawerPages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);

    Future<void> openProfile() async {
      // Popping the drawer disposes this ConsumerWidget. Keep the application
      // provider container before navigating so the profile can be refreshed
      // safely when the profile route is closed.
      final container = ProviderScope.containerOf(context);
      router.pop();
      await router.push<void>(AppRoutes.profile);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.invalidate(appShellProfileProvider);
      });
    }
    void openPage(String route) {
      router.pop();
      router.push<void>(route);
    }
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
      DrawerItem(icon: Icons.person_outline_rounded, label: AppStrings.profile, onTap: openProfile),
      const SizedBox(height: 6),
      DrawerItem(icon: Icons.category_outlined, label: 'Categories', onTap: () => openPage(AppRoutes.categories)),
      const SizedBox(height: 6),
      DrawerItem(icon: Icons.note_alt_outlined, label: AppStrings.notes, onTap: () => openPage(AppRoutes.notes)),
      const SizedBox(height: 6),
      DrawerItem(icon: Icons.settings_outlined, label: AppStrings.settings, onTap: () => openPage(AppRoutes.settings)),
    ]);
  }
}
