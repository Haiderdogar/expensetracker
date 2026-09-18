import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../auth/auth_screen.dart';
import 'app_shell_providers.dart';

enum _LogoutChoice { cancel, logout, upgrade }


class AppShellLogoutButton extends ConsumerWidget {
  const AppShellLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(appShellLogoutInProgressProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Material(
            color: isDark
                ? colors.error.withValues(alpha: 0.1)
                : colors.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: busy ? null : () => _logout(context, ref),
              borderRadius: BorderRadius.circular(14),
              splashColor: colors.error.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.error.withValues(
                          alpha: isDark ? 0.25 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: busy
                          ? Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colors.error,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.logout_rounded,
                              size: 19,
                              color: colors.error,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.logout,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (!busy)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colors.error.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(authControllerProvider).value == AuthStatus.guest;

    // ── Step 1: Show confirmation dialog ──────────────────────────────────
    final choice = await showDialog<_LogoutChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: Text(
          isGuest
              ? AppStrings.guestLogoutWarning
              : AppStrings.logoutConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LogoutChoice.cancel),
            child: const Text(AppStrings.cancel),
          ),
          if (isGuest)
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _LogoutChoice.upgrade),
              child: const Text(AppStrings.signInWithGoogle),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, _LogoutChoice.logout),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (choice == _LogoutChoice.upgrade) {
      ref.read(appShellLogoutInProgressProvider.notifier).state = true;
      try {
        final result = await ref
            .read(authControllerProvider.notifier)
            .signInWithGoogle();
        if (result != GoogleSignInResult.success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google upgrade was not completed.')),
          );
        }
        if (result == GoogleSignInResult.success) {
          _invalidateAccountScopedProviders(ref);
        }
      } finally {
        if (context.mounted) {
          ref.read(appShellLogoutInProgressProvider.notifier).state = false;
        }
      }
      return;
    }

    if (choice != _LogoutChoice.logout || !context.mounted) return;

    // ── Step 2: Identity verification (PIN / biometric) ───────────────────
    final storage = ref.read(secureStorageProvider);
    final pinOn = await storage.hasConfiguredPinLock();
    final biometricOn = await storage.hasConfiguredBiometricLock();
    final needsVerification = pinOn || biometricOn;

    if (needsVerification && context.mounted) {
      // Try biometric first (fast, non-blocking)
      var authenticated = false;
      if (biometricOn) {
        authenticated = await ref
            .read(authControllerProvider.notifier)
            .promptBiometric(reason: 'Confirm logout');
      }

      // If biometric failed/not used, fall back to PIN screen.
      // Closing the drawer first so the PIN screen has clean navigation.
      if (!authenticated) {
        if (!context.mounted) return;
        if (appShellScaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop(); // close drawer
          await WidgetsBinding.instance.endOfFrame;
        }
        if (!context.mounted) return;
        // Push PIN verification screen. Pressing the back button (hardware or
        // AppBar) returns `null`/`false` — we treat that as cancelled.
        final pinResult = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                const AuthScreen(verifyOnly: true, isLogoutConfirmation: true),
          ),
        );
        if (pinResult != true || !context.mounted) {
          // User cancelled — do nothing, they're already back at the main screen.
          return;
        }
        authenticated = true;
      }

      if (!authenticated || !context.mounted) return;
    }

    ref.read(appShellLogoutInProgressProvider.notifier).state = true;
    try {
      if (context.mounted &&
          (appShellScaffoldKey.currentState?.isDrawerOpen ?? false)) {
        Navigator.of(context).pop();
        await WidgetsBinding.instance.endOfFrame;
      }

      _invalidateAccountScopedProviders(ref);
      if (isGuest) {
        await ref
            .read(authControllerProvider.notifier)
            .discardGuestDataAndSignOut();
      } else {
        await ref.read(authControllerProvider.notifier).signOut();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (context.mounted) {
        ref.read(appShellLogoutInProgressProvider.notifier).state = false;
      }
    }
  }

  void _invalidateAccountScopedProviders(WidgetRef ref) {
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(budgetsProvider);
    ref.invalidate(notesProvider);
    ref.invalidate(backupServiceProvider);
    ref.invalidate(selectedWalletIdProvider);
    ref.invalidate(onboardingCompleteProvider);
    ref.invalidate(currencySymbolProvider);
    ref.invalidate(currencyCodeProvider);
    ref.invalidate(appShellProfileProvider);
    ref.read(appShellNavigationIndexProvider.notifier).state = 0;
    ref.read(appShellVisitedIndexesProvider.notifier).state = {0};
  }
}
