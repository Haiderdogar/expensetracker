import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/core/constants/app_strings.dart';
import 'package:expensetracker/core/router/app_router.dart';
import 'package:expensetracker/core/utils/app_currency_picker.dart';
import 'package:expensetracker/features/google_sign_in/providers/auth_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/currency_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_setup_providers.dart';
import 'package:expensetracker/providers/database_provider.dart';
import 'package:expensetracker/widgets/custom_button.dart';
import 'package:expensetracker/widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';

/// Account setup shown after login. This is deliberately separate from the
/// introductory onboarding carousel shown on first launch.
class WalletCurrencySetupScreen extends StatelessWidget {
  const WalletCurrencySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const _WelcomeArtwork(),
                const SizedBox(height: 24),
                const _OnboardingHeader(),
                const SizedBox(height: 28),
                const _WalletNameInput(),
                const SizedBox(height: 24),
                const _CurrencySelector(),
                const SizedBox(height: 32),
                const _OnboardingSubmitButton(),
              ],
            ),
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
      isLoading: false,
      onPressed: () async {
        if (draft.isLoading) return;
        if (draft.walletName.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a wallet name')),
          );
          return;
        }
        ref.read(onboardingDraftProvider.notifier).setLoading(true);
        FocusManager.instance.primaryFocus?.unfocus();
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              title: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5EF),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF087F5B),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Setting up your wallet')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preparing your wallet and preferences...'),
                  SizedBox(height: 20),
                  LinearProgressIndicator(
                    minHeight: 6,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ],
              ),
            ),
          ),
        );

        try {
          final userId = ref.read(currentUserIdProvider);
          final helper = ref.read(databaseHelperProvider);
          await Future.wait([
            helper.setCurrencySymbol(draft.currencySymbol, userId),
            helper.setSetting('currency_code_$userId', draft.currencyCode),
            helper.setSetting('currency_code', draft.currencyCode),
          ]);
          final walletName = draft.walletName.trim();
          await ref.read(walletsProvider.notifier).create(name: walletName);
          await ref
              .read(secureStorageProvider)
              .setSecuritySetupPending(userId, true);
          ref.invalidate(walletsProvider);
          ref.invalidate(currencySymbolProvider);
          ref.invalidate(currencyCodeProvider);
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            context.go(AppRoutes.securitySetup);
          }
        } catch (error) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
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
