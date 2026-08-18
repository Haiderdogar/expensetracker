import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../app_shell.dart';

final _walletNameProvider = StateProvider.autoDispose<String>(
  (ref) => 'Main Wallet',
);
final _currencyProvider = StateProvider.autoDispose<String>((ref) => '\$');
final _loadingOnboardingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _currencies = [
    '\$',
    '€',
    '£',
    '₹',
    '¥',
    'PKR',
    'AED',
    'SAR',
    'BDT',
    'JPY',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final walletName = ref.watch(_walletNameProvider);
        final currency = ref.watch(_currencyProvider);
        final loading = ref.watch(_loadingOnboardingProvider);

        Future<void> complete() async {
          if (walletName.trim().isEmpty) return;
          ref.read(_loadingOnboardingProvider.notifier).state = true;

          try {
            final helper = ref.read(databaseHelperProvider);
            await helper.setCurrencySymbol(currency);
            await ref
                .read(walletsProvider.notifier)
                .create(name: walletName.trim());
            await helper.setOnboardingComplete(true);
            ref.invalidate(onboardingCompleteProvider);
            ref.invalidate(currencySymbolProvider);

            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const AppShell()),
            );
          } finally {
            if (context.mounted)
              ref.read(_loadingOnboardingProvider.notifier).state = false;
          }
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    AppStrings.welcome,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.setupWallet,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    initialValue: walletName,
                    label: AppStrings.walletName,
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    onChanged: (v) =>
                        ref.read(_walletNameProvider.notifier).state = v,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.selectCurrency,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _currencies.map((c) {
                      final selected = c == currency;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (_) =>
                            ref.read(_currencyProvider.notifier).state = c,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    initialValue: currency,
                    label: 'Custom currency',
                    hint: 'PKR, USD, AED, etc.',
                    prefix: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(currency),
                    ),
                    onChanged: (value) {
                      final sanitized = value.trim();
                      if (sanitized.isNotEmpty) {
                        ref.read(_currencyProvider.notifier).state = sanitized;
                      }
                    },
                  ),
                  const Spacer(),
                  CustomButton(
                    label: AppStrings.getStarted,
                    isLoading: loading,
                    onPressed: complete,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
