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
import 'notes/notes_screen.dart';
import 'transactions/transactions_screen.dart';
import 'profile/profile_view_screen.dart';
import '../../models/wallet_model.dart';
import '../../providers/database_provider.dart';
import '../../providers/wallet_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(_navIndexProvider);
    _visited.add(index);

    final name = _profileName;
    final email = _profileEmail;
    final wallets = ref.watch(walletsProvider).value ?? const <WalletModel>[];
    final selectedWalletId = ref.watch(selectedWalletIdProvider);
    final selectedWallets = wallets
        .where((wallet) => wallet.id == selectedWalletId)
        .toList();
    final walletName = selectedWallets.isNotEmpty
        ? selectedWallets.first.name
        : (wallets.isNotEmpty ? wallets.first.name : 'Wallet');

    return Scaffold(
      key: appShellScaffoldKey,
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Guest User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isNotEmpty ? email : 'Add your email',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  walletName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Pages',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    DrawerItem(
                      icon: Icons.person_outline_rounded,
                      label: AppStrings.profile,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileViewScreen(),
                          ),
                        );
                        _loadProfile();
                      },
                    ),
                    const SizedBox(height: 6),
                    DrawerItem(
                      icon: Icons.note_alt_outlined,
                      label: AppStrings.notes,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 6),
                    // Add other Drawer items here as needed
                  ],
                ),
              ),

              // Logout button pinned to bottom
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 16.0,
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    onTap: _logout,
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      AppStrings.logout,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.red,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
