import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/app_currency_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../auth/auth_screen.dart';

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

  static Future<void> importData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;
      final json = await File(result.files.single.path!).readAsString();
      await ref.read(backupServiceProvider.notifier).importFromJson(json);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(budgetsProvider);
      if (context.mounted) _message(context, AppStrings.importSuccess);
    } catch (error) {
      if (context.mounted) _message(context, error.toString());
    }
  }

  static Future<void> chooseCurrency(BuildContext context, WidgetRef ref) async {
    showAppCurrencyPicker(
      context: context,
      onSelect: (currency) async {
        try {
          final database = ref.read(databaseHelperProvider);
          await database.setCurrencySymbol(currency.symbol);
          await database.setSetting('currency_code', currency.code);
          ref.invalidate(currencySymbolProvider);
          ref.invalidate(currencyCodeProvider);
          if (context.mounted) _message(context, 'Currency set to ${currency.code}');
        } catch (error) {
          if (context.mounted) _message(context, error.toString());
        }
      },
    );
  }

  static Future<void> toggleBiometric(BuildContext context, WidgetRef ref, bool enabled) async {
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
      if (context.mounted) _message(context, 'Biometrics are not available on this device');
      return;
    }
    if (!await controller.promptBiometric(reason: 'Confirm biometrics for Expense Tracker')) {
      if (context.mounted) _message(context, 'Biometric setup was cancelled');
      return;
    }
    if (!await controller.enableBiometricUnlock()) {
      if (context.mounted) _message(context, 'Failed to enable biometric authentication');
      return;
    }
    ref.invalidate(biometricEnabledProvider);
  }

  static Future<void> togglePin(BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen(isSetup: true, offerBiometricAfterSetup: true)));
      ref.invalidate(pinEnabledProvider);
      ref.invalidate(biometricEnabledProvider);
      return;
    }
    final verified = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen(verifyOnly: true)));
    if (verified == true) await ref.read(authControllerProvider.notifier).disablePin();
  }

  static Future<void> editPin(BuildContext context, WidgetRef ref, bool enabled) async {
    if (!enabled) return togglePin(context, ref, true);
    final verified = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen(verifyOnly: true)));
    if (verified == true && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen(isSetup: true)));
    }
    ref.invalidate(pinEnabledProvider);
  }

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
