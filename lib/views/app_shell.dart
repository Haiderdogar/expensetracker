import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import '../../widgets/glass_navbar.dart';
import 'analytics/analytics_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/transactions_screen.dart';
import 'profile/profile_view_screen.dart';
import '../../providers/database_provider.dart';
import 'package:expensetracker/views/app_shell_drawer_item.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const AnalyticsScreen(),
      const BudgetsScreen(),
    ];

    return Consumer(
      builder: (context, ref, _) {
        final index = ref.watch(_navIndexProvider);
        return Scaffold(
          key: appShellScaffoldKey,
          drawer: Drawer(
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Header
                          SizedBox(
                            height: 200,
                            child: FutureBuilder<List<String?>>(
                              future: Future.wait([
                                ref.read(databaseHelperProvider).getSetting('profile_name'),
                                ref.read(databaseHelperProvider).getSetting('profile_email'),
                              ]),
                              builder: (context, snap) {
                                final name = snap.hasData ? (snap.data![0] ?? '') : '';
                                final email = snap.hasData ? (snap.data![1] ?? '') : '';
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Colors.white24,
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                          style: const TextStyle(fontSize: 32, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isNotEmpty ? name : 'Guest User',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              email.isNotEmpty ? email : 'Add your details',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white24,
                                                    elevation: 0,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileViewScreen()));
                                                  },
                                                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                                  label: const Text('View profile', style: TextStyle(color: Colors.white)),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                                  },
                                                  child: const Text('Settings', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              children: [
                                DrawerItem(
                                  icon: Icons.dashboard_outlined,
                                  label: AppStrings.dashboard,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    ref.read(_navIndexProvider.notifier).state = 0;
                                  },
                                ),
                                DrawerItem(
                                  icon: Icons.receipt_long_outlined,
                                  label: AppStrings.transactions,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    ref.read(_navIndexProvider.notifier).state = 1;
                                  },
                                ),
                                DrawerItem(
                                  icon: Icons.pie_chart_outline,
                                  label: AppStrings.analytics,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    ref.read(_navIndexProvider.notifier).state = 2;
                                  },
                                ),
                                DrawerItem(
                                  icon: Icons.savings_outlined,
                                  label: AppStrings.budgets,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    ref.read(_navIndexProvider.notifier).state = 3;
                                  },
                                ),
                                const Divider(),
                                DrawerItem(
                                  icon: Icons.person_outline,
                                  label: AppStrings.profile,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileViewScreen()));
                                  },
                                ),
                                DrawerItem(
                                  icon: Icons.settings_outlined,
                                  label: AppStrings.settings,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
