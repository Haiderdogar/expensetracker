import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/app_currency_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backup_provider.dart';
import '../../features/wallet_currency/providers/currency_provider.dart';
import '../../providers/database_provider.dart';

class SettingsActions {
  const SettingsActions._();

  static Future<void> exportData(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupServiceProvider.notifier).shareExport();
      if (context.mounted) _message(context, AppStrings.backupSuccess);
    } catch (error) {
      if (context.mounted) _message(context, error.toString());
    }
  }

  static Future<void> chooseCurrency(
    BuildContext context,
    WidgetRef ref,
  ) async {
    showAppCurrencyPicker(
      context: context,
      onSelect: (currency) async {
        try {
          final database = ref.read(databaseHelperProvider);
          await database.setCurrencySymbol(currency.symbol);
          await database.setSetting('currency_code', currency.code);
          ref.invalidate(currencySymbolProvider);
          ref.invalidate(currencyCodeProvider);
          if (context.mounted)
            _message(context, 'Currency set to ${currency.code}');
        } catch (error) {
          if (context.mounted) _message(context, error.toString());
        }
      },
    );
  }

  static Future<void> toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (!enabled) {
      await ref.read(secureStorageProvider).setBiometricEnabled(false);
      ref.invalidate(biometricEnabledProvider);
      return;
    }
    if (!await ref.read(pinEnabledProvider.future)) {
      if (context.mounted) _message(context, 'Enable PIN lock first');
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    if (!await controller.isBiometricAvailable()) {
      if (context.mounted)
        _message(context, 'Biometrics are not available on this device');
      return;
    }
    if (!await controller.promptBiometric(
      reason: 'Confirm biometrics for Expense Tracker',
    )) {
      if (context.mounted) _message(context, 'Biometric setup was cancelled');
      return;
    }
    if (!await controller.enableBiometricUnlock()) {
      if (context.mounted)
        _message(context, 'Failed to enable biometric authentication');
      return;
    }
    ref.invalidate(biometricEnabledProvider);
  }

  static Future<void> togglePin(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled) {
      await context.push<void>(AppRoutes.pinSetup);
      ref.invalidate(pinEnabledProvider);
      ref.invalidate(biometricEnabledProvider);
      return;
    }
    final verified = await context.push<bool>(AppRoutes.pinVerify);
    if (verified == true)
      await ref.read(authControllerProvider.notifier).disablePin();
  }

  static Future<void> editPin(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (!enabled) return togglePin(context, ref, true);
    final verified = await context.push<bool>(AppRoutes.pinVerify);
    if (verified == true && context.mounted) {
      await context.push<void>(AppRoutes.pinSetup);
    }
    ref.invalidate(pinEnabledProvider);
  }

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
