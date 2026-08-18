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
              child: ListView(
                          padding: const EdgeInsets.all(0),
                children: [
                            SizedBox(
                              height: 180,
                              child: FutureBuilder<List<String?>>(
                                future: Future.wait([
                                  ref.read(databaseHelperProvider).getSetting('profile_name'),
                                  ref.read(databaseHelperProvider).getSetting('profile_email'),
                                ]),
                                builder: (context, snap) {
                                  final name = snap.hasData ? (snap.data![0] ?? '') : '';
                                  final email = snap.hasData ? (snap.data![1] ?? '') : '';
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: Colors.white24,
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                            style: const TextStyle(fontSize: 28, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name.isNotEmpty ? name : 'Guest User',
                                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                email.isNotEmpty ? email : 'Add your details',
                                                style: const TextStyle(color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileViewScreen()));
                                          },
                                          icon: const Icon(Icons.edit, color: Colors.white),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: const Icon(Icons.dashboard_outlined),
                              title: const Text(AppStrings.dashboard),
                              onTap: () {
                                Navigator.of(context).pop();
                                ref.read(_navIndexProvider.notifier).state = 0;
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.receipt_long_outlined),
                              title: const Text(AppStrings.transactions),
                              onTap: () {
                                Navigator.of(context).pop();
                                ref.read(_navIndexProvider.notifier).state = 1;
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.pie_chart_outline),
                              title: const Text(AppStrings.analytics),
                              onTap: () {
                                Navigator.of(context).pop();
                                ref.read(_navIndexProvider.notifier).state = 2;
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.savings_outlined),
                              title: const Text(AppStrings.budgets),
                              onTap: () {
                                Navigator.of(context).pop();
                                ref.read(_navIndexProvider.notifier).state = 3;
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.settings_outlined),
                              title: const Text(AppStrings.settings),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
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
