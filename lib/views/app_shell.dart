import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/global_keys.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/glass_navbar.dart';
import 'auth/auth_screen.dart';
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

final _navIndexProvider = StateProvider.autoDispose<int>((_) => 0);

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
  bool _isLoggingOut = false;

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
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            title: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, color: colors.error),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppStrings.logout,
                    style: Theme.of(dialogContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.logoutConfirmation,
                      style: Theme.of(dialogContext).textTheme.bodyMedium
                          ?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(AppStrings.logout),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) return;

      final storage = ref.read(secureStorageProvider);
      final pinOn = await storage.hasConfiguredPinLock();
      final biometricOn = await storage.hasConfiguredBiometricLock();
      if (!mounted) return;

      var authenticated = false;
      if (pinOn || biometricOn) {
        // Prefer biometrics, then fall back to PIN when both are enabled.
        if (biometricOn) {
          authenticated = await ref
              .read(authControllerProvider.notifier)
              .promptBiometric(reason: AppStrings.logout);
        }

        if (!authenticated && pinOn && mounted) {
          authenticated =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(verifyOnly: true),
                ),
              ) ==
              true;
        }
      } else {
        // No lock is configured, so confirmation is the only required check.
        authenticated = true;
      }

      if (!authenticated || !mounted) return;

      if (appShellScaffoldKey.currentState?.isDrawerOpen ?? false) {
        Navigator.of(context).pop();
      }

      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final databaseHelper = ref.read(databaseHelperProvider);
      final hasSeenIntro = await storage.hasSeenIntroOnboarding();
      await databaseHelper.resetDatabase();
      await storage.clearAll();
      await databaseHelper.initializeInstallationIdentity(storage);
      if (hasSeenIntro) await storage.setIntroOnboardingSeen();

      // Dispose cached account data before the welcome flow reads the newly
      // created database. Screen-scoped providers dispose with their screens.
      ref.invalidate(databaseProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(notesProvider);
      ref.invalidate(backupServiceProvider);
      ref.invalidate(selectedWalletIdProvider);
      ref.invalidate(pinEnabledProvider);
      ref.invalidate(biometricEnabledProvider);
      ref.invalidate(lockPromptCompletedProvider);
      ref.invalidate(introOnboardingSeenProvider);
      ref.invalidate(onboardingCompleteProvider);
      ref.invalidate(currencySymbolProvider);
      ref.invalidate(currencyCodeProvider);
      ref.invalidate(themeModeControllerProvider);
      ref.read(_navIndexProvider.notifier).state = 0;
      await ref.read(authControllerProvider.notifier).logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      _isLoggingOut = false;
    }
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
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
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
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isNotEmpty ? email : 'Add your email',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  walletName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.78,
                                        ),
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
