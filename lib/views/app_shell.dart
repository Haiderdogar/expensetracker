import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../widgets/glass_navbar.dart';
import 'analytics/analytics_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/transactions_screen.dart';

final _navIndexProvider = StateProvider<int>((_) => 0);

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _items = [
    GlassNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: AppStrings.dashboard,
    ),
    GlassNavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: AppStrings.transactions,
    ),
    GlassNavItem(
      icon: Icons.pie_chart_outline,
      activeIcon: Icons.pie_chart,
      label: AppStrings.analytics,
    ),
    GlassNavItem(
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings,
      label: AppStrings.budgets,
    ),
    GlassNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: AppStrings.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const AnalyticsScreen(),
      const BudgetsScreen(),
      const SettingsScreen(),
    ];

    return Consumer(
      builder: (context, ref, _) {
        final index = ref.watch(_navIndexProvider);
        return Scaffold(
          body: IndexedStack(index: index, children: screens),
          extendBody: true,
          bottomNavigationBar: GlassNavbar(
            currentIndex: index,
            onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
            items: _items,
          ),
        );
      },
    );
  }
}
