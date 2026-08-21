import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/app_currency_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

final _walletNameProvider = StateProvider.autoDispose<String>(
  (ref) => 'Main Wallet',
);
final _currencySymbolProvider = StateProvider.autoDispose<String>((ref) => '\$');
final _currencyCodeProvider = StateProvider.autoDispose<String>((ref) => 'USD');
final _loadingOnboardingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final walletName = ref.watch(_walletNameProvider);
        final currencySymbol = ref.watch(_currencySymbolProvider);
        final currencyCode = ref.watch(_currencyCodeProvider);
        final loading = ref.watch(_loadingOnboardingProvider);

        Future<void> complete() async {
          if (walletName.trim().isEmpty) return;
          ref.read(_loadingOnboardingProvider.notifier).state = true;

          try {
            final helper = ref.read(databaseHelperProvider);
            await helper.setCurrencySymbol(currencySymbol);
            await helper.setSetting('currency_code', currencyCode);
            await ref
                .read(walletsProvider.notifier)
                .create(name: walletName.trim());
            await helper.setOnboardingComplete(true);
            ref.invalidate(onboardingCompleteProvider);
            ref.invalidate(currencySymbolProvider);
            ref.invalidate(currencyCodeProvider);
          } finally {
            if (context.mounted) {
              ref.read(_loadingOnboardingProvider.notifier).state = false;
            }
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
                            ref.read(_currencySymbolProvider.notifier).state =
                                currency.symbol;
                            ref.read(_currencyCodeProvider.notifier).state =
                                currency.code;
                          },
                        );
                      },
                      child: const Text('Change'),
                    ),
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
