import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/core/constants/app_strings.dart';
import 'package:expensetracker/app/app_startup.dart';
import 'package:expensetracker/core/utils/app_currency_picker.dart';
import 'package:expensetracker/features/google_sign_in/providers/auth_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/currency_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_setup_providers.dart';
import 'package:expensetracker/providers/database_provider.dart';
import 'package:expensetracker/widgets/custom_button.dart';
import 'package:expensetracker/widgets/custom_text_field.dart';

/// Account setup shown after login. This is deliberately separate from the
/// introductory onboarding carousel shown on first launch.
class WalletCurrencySetupScreen extends StatelessWidget {
  const WalletCurrencySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacer(),
              _WelcomeArtwork(),
              SizedBox(height: 24),
              _OnboardingHeader(),
              SizedBox(height: 28),
              _WalletNameInput(),
              SizedBox(height: 24),
              _CurrencySelector(),
              Spacer(),
              const _OnboardingSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 148,
        height: 148,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
        ),
        child: Image.asset(
          'assets/icon.png',
          fit: BoxFit.contain,
          semanticLabel: 'Expense Tracker wallet',
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.welcome,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.setupWallet,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _WalletNameInput extends ConsumerWidget {
  const _WalletNameInput();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletName = ref.watch(
      onboardingDraftProvider.select((d) => d.walletName),
    );

    return CustomTextField(
      initialValue: walletName,
      label: AppStrings.walletName,
      prefixIcon: Icons.account_balance_wallet_outlined,
      onChanged: (v) =>
          ref.read(onboardingDraftProvider.notifier).setWalletName(v),
    );
  }
}

class _CurrencySelector extends ConsumerWidget {
  const _CurrencySelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(
      onboardingDraftProvider.select((d) => d.currencySymbol),
    );
    final currencyCode = ref.watch(
      onboardingDraftProvider.select((d) => d.currencyCode),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectCurrency,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(
            currencySymbol,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          title: Text('Currency: $currencyCode'),
          trailing: TextButton(
            onPressed: () {
              showAppCurrencyPicker(
                context: context,
                onSelect: (currency) {
                  ref
                      .read(onboardingDraftProvider.notifier)
                      .setCurrency(currency.symbol, currency.code);
                },
              );
            },
            child: const Text('Change'),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSubmitButton extends ConsumerWidget {
  const _OnboardingSubmitButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);

    return CustomButton(
      label: AppStrings.getStarted,
      isLoading: draft.isLoading,
      onPressed: () async {
        if (draft.walletName.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a wallet name')),
          );
          return;
        }
        ref.read(onboardingDraftProvider.notifier).setLoading(true);

        try {
          final userId = ref.read(currentUserIdProvider);
          final helper = ref.read(databaseHelperProvider);
          await helper.setCurrencySymbol(draft.currencySymbol, userId);
          await helper.setSetting('currency_code_$userId', draft.currencyCode);
          await helper.setSetting('currency_code', draft.currencyCode);
          final walletName = draft.walletName.trim();
          await ref.read(walletsProvider.notifier).create(name: walletName);
          await ref.read(secureStorageProvider).setSecuritySetupPending(userId, true);
          ref.invalidate(walletsProvider);
          ref.invalidate(currencySymbolProvider);
          ref.invalidate(currencyCodeProvider);
          ref.invalidate(appStartupControllerProvider);
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not finish setup: $error')),
            );
          }
        } finally {
          ref.read(onboardingDraftProvider.notifier).setLoading(false);
        }
      },
    );
  }
}
