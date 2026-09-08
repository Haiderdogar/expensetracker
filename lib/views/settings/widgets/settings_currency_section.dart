import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/currency_provider.dart';
import '../settings_actions.dart';
import 'settings_tile.dart';

class SettingsCurrencySection extends StatelessWidget {
  const SettingsCurrencySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider);
        final code = ref.watch(currencyCodeProvider);
        return symbol.when(
          loading: () => const ListTile(
            leading: Icon(Icons.money_rounded),
            title: Text('Currency: ...'),
            trailing: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => ListTile(
            leading: const Icon(Icons.money_rounded),
            title: Text('Currency: error: $error'),
          ),
          data: (symbol) => SettingsTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Currency',
            subtitle: code.value ?? symbol,
            trailing: FilledButton.tonal(
              onPressed: () => SettingsActions.chooseCurrency(context, ref),
              child: const Text('Change'),
            ),
          ),
        );
      },
    );
  }
}
