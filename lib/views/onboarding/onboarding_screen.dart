import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/app_currency_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'onboarding_ui_providers.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacer(),
              _OnboardingHeader(),
              SizedBox(height: 32),
              _WalletNameInput(),
              SizedBox(height: 24),
              _CurrencySelector(),
              Spacer(),
              _OnboardingSubmitButton(),
            ],
          ),
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
          final wallets = await ref.read(walletsProvider.future);
          final walletName = draft.walletName.trim();
          if (wallets.isEmpty) {
            await ref.read(walletsProvider.notifier).create(name: walletName);
          } else {
            await ref
                .read(walletsProvider.notifier)
                .updateWallet(wallets.first.copyWith(name: walletName));
          }
          await helper.setOnboardingComplete(true, userId);
          ref.invalidate(onboardingCompleteProvider);
          ref.invalidate(currencySymbolProvider);
          ref.invalidate(currencyCodeProvider);
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
