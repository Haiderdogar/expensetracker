import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../widgets/glass_navbar.dart';
import 'app_shell_providers.dart';

class AppShellBottomNavigation extends ConsumerWidget {
  const AppShellBottomNavigation({super.key});

  static const _items = [
    GlassNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: AppStrings.dashboard),
    GlassNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: AppStrings.transactions),
    GlassNavItem(icon: Icons.pie_chart_outline, activeIcon: Icons.pie_chart, label: AppStrings.analytics),
    GlassNavItem(icon: Icons.savings_outlined, activeIcon: Icons.savings, label: AppStrings.budgets),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassNavbar(
      currentIndex: ref.watch(appShellNavigationIndexProvider),
      items: _items,
      onTap: (index) {
        ref.read(appShellNavigationIndexProvider.notifier).state = index;
        ref.read(appShellVisitedIndexesProvider.notifier).update(
          (visited) => {...visited, index},
        );
      },
    );
  }
}
