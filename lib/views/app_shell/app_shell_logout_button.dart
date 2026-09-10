import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_provider.dart';
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

class AppShellLogoutButton extends ConsumerWidget {
  const AppShellLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(appShellLogoutInProgressProvider);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: busy ? null : () => _logout(context, ref),
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: Text(
            AppStrings.logout,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right_rounded, color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // ── Step 1: Show confirmation dialog ──────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

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
            builder: (_) => const AuthScreen(
              verifyOnly: true,
              isLogoutConfirmation: true,
            ),
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

    // ── Step 3: Wipe all data ─────────────────────────────────────────────
    ref.read(appShellLogoutInProgressProvider.notifier).state = true;
    try {
      // Close drawer if still open (e.g. biometric confirmed without closing it)
      if (context.mounted &&
          (appShellScaffoldKey.currentState?.isDrawerOpen ?? false)) {
        Navigator.of(context).pop();
        await WidgetsBinding.instance.endOfFrame;
      }

      final database = ref.read(databaseHelperProvider);
      final seenIntro = await storage.hasSeenIntroOnboarding();
      await database.resetDatabase();
      await storage.clearAll();
      await database.initializeInstallationIdentity(storage);
      // Preserve the intro flag so returning users skip the intro slides.
      if (seenIntro) await storage.setIntroOnboardingSeen();

      // Invalidate all cached providers so AppBootstrap re-evaluates state.
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
      ref.read(appShellNavigationIndexProvider.notifier).state = 0;
      ref.read(appShellVisitedIndexesProvider.notifier).state = {0};

      // Set auth to authenticated so AppBootstrap's navigation logic runs
      // normally. With onboardingComplete = false (DB wiped), it will route
      // to OnboardingScreen (the welcome screen).
      await ref.read(authControllerProvider.notifier).logoutAndReset();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (context.mounted) {
        ref.read(appShellLogoutInProgressProvider.notifier).state = false;
      }
    }
  }
}
