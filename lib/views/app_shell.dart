import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import '../../providers/auth_provider.dart';
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

class AppShell extends ConsumerStatefulWidget {
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

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    BudgetsScreen(),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final Set<int> _visited = {0};
  String _profileName = '';
  String _profileEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final helper = ref.read(databaseHelperProvider);
    final results = await Future.wait([
      helper.getSetting('profile_name'),
      helper.getSetting('profile_email'),
    ]);
    if (!mounted) return;
    setState(() {
      _profileName = results[0] ?? '';
      _profileEmail = results[1] ?? '';
    });
  }

  Future<void> _logout() async {
    final pinOn = await ref.read(pinEnabledProvider.future);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!pinOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable PIN lock to log out')),
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).logout();
  }

  void _onHeaderAction(String action) {
    switch (action) {
      case 'profile':
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileViewScreen()),
        );
      case 'settings':
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      case 'logout':
        _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(_navIndexProvider);
    _visited.add(index);

    final name = _profileName;
    final email = _profileEmail;

    return Scaffold(
      key: appShellScaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 232,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white24,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                ),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    email.isNotEmpty
                                        ? email
                                        : 'Add your details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SegmentedButton<String>(
                        emptySelectionAllowed: true,
                        showSelectedIcon: false,
                        selected: const <String>{},
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                          visualDensity: VisualDensity.compact,
                          side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.white24),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: 'profile',
                            label: Text('Profile'),
                            icon: Icon(Icons.person_outline, size: 16),
                          ),
                          ButtonSegment(
                            value: 'settings',
                            label: Text(AppStrings.settings),
                            icon: Icon(Icons.settings_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: 'logout',
                            label: Text(AppStrings.logout),
                            icon: Icon(Icons.logout, size: 16),
                          ),
                        ],
                        onSelectionChanged: (selection) {
                          if (selection.isEmpty) return;
                          _onHeaderAction(selection.single);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileViewScreen(),
                          ),
                        );
                      },
                    ),
                    DrawerItem(
                      icon: Icons.settings_outlined,
                      label: AppStrings.settings,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < AppShell._screens.length; i++)
            _visited.contains(i)
                ? AppShell._screens[i]
                : const SizedBox.shrink(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: GlassNavbar(
        currentIndex: index,
        onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
        items: AppShell._items,
      ),
    );
  }
}
