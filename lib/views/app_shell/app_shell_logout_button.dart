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
      child: Material(color: colors.errorContainer, borderRadius: BorderRadius.circular(14), child: ListTile(
        onTap: busy ? null : () => _logout(context, ref),
        leading: const Icon(Icons.logout_rounded, color: Colors.red),
        title: Text(AppStrings.logout, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.error, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
      )),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(appShellLogoutInProgressProvider.notifier).state = true;
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirmation),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text(AppStrings.cancel)), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text(AppStrings.logout))],
      ));
      if (confirmed != true || !context.mounted) return;
      final storage = ref.read(secureStorageProvider);
      final pinOn = await storage.hasConfiguredPinLock();
      final biometricOn = await storage.hasConfiguredBiometricLock();
      var authenticated = !(pinOn || biometricOn);
      if (biometricOn) authenticated = await ref.read(authControllerProvider.notifier).promptBiometric(reason: AppStrings.logout);
      if (!authenticated && pinOn && context.mounted) authenticated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen(verifyOnly: true))) == true;
      if (!authenticated || !context.mounted) return;
      if (appShellScaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.of(context).pop();
      await WidgetsBinding.instance.endOfFrame;
      final database = ref.read(databaseHelperProvider);
      final seenIntro = await storage.hasSeenIntroOnboarding();
      await database.resetDatabase();
      await storage.clearAll();
      await database.initializeInstallationIdentity(storage);
      if (seenIntro) await storage.setIntroOnboardingSeen();
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
      await ref.read(authControllerProvider.notifier).logout();
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      ref.read(appShellLogoutInProgressProvider.notifier).state = false;
    }
  }
}
