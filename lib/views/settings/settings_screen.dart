import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../auth/auth_screen.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupServiceProvider.notifier).shareExport();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.backupSuccess)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final json = await File(result.files.single.path!).readAsString();
      await ref.read(backupServiceProvider.notifier).importFromJson(json);

      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(budgetsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.importSuccess)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    await ref.read(secureStorageProvider).setBiometricEnabled(value);
    ref.invalidate(biometricEnabledProvider);
  }

  Future<void> _togglePinLock(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (value) {
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AuthScreen(isSetup: true),
          ),
        );
      }
      ref.invalidate(pinEnabledProvider);
      return;
    }

    await ref.read(secureStorageProvider).setPinEnabled(false);
    await ref.read(authControllerProvider.notifier).lock();
    ref.invalidate(pinEnabledProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final biometricAsync = ref.watch(biometricEnabledProvider);
    final pinEnabledAsync = ref.watch(pinEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              AppStrings.theme,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SettingsTile(
            icon: Icons.light_mode_outlined,
            title: AppStrings.lightMode,
            trailing: Radio<AppThemeMode>(
              value: AppThemeMode.light,
              groupValue: themeMode,
              onChanged: (v) {
                if (v != null) {
                  ref.read(themeModeControllerProvider.notifier).setMode(v);
                }
              },
            ),
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .setMode(AppThemeMode.light),
          ),
          SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: AppStrings.darkMode,
            trailing: Radio<AppThemeMode>(
              value: AppThemeMode.dark,
              groupValue: themeMode,
              onChanged: (v) {
                if (v != null) {
                  ref.read(themeModeControllerProvider.notifier).setMode(v);
                }
              },
            ),
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .setMode(AppThemeMode.dark),
          ),
          SettingsTile(
            icon: Icons.brightness_auto_outlined,
            title: AppStrings.systemMode,
            trailing: Radio<AppThemeMode>(
              value: AppThemeMode.system,
              groupValue: themeMode,
              onChanged: (v) {
                if (v != null) {
                  ref.read(themeModeControllerProvider.notifier).setMode(v);
                }
              },
            ),
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .setMode(AppThemeMode.system),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              AppStrings.security,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          pinEnabledAsync.when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('PIN lock'),
            ),
            error: (e, _) => ListTile(title: Text(e.toString())),
            data: (enabled) => SettingsTile(
              icon: Icons.pin_outlined,
              title: enabled ? AppStrings.changePin : 'Enable PIN lock',
              trailing: Switch(
                value: enabled,
                onChanged: (v) => _togglePinLock(context, ref, v),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AuthScreen(isSetup: true),
                ),
              ),
            ),
          ),
          biometricAsync.when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text(AppStrings.enableBiometric),
            ),
            error: (e, _) => ListTile(title: Text(e.toString())),
            data: (enabled) => SettingsTile(
              icon: Icons.fingerprint,
              title: AppStrings.enableBiometric,
              trailing: Switch(
                value: enabled,
                onChanged: (v) => _toggleBiometric(context, ref, v),
              ),
              onTap: () => _toggleBiometric(context, ref, !enabled),
            ),
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.upload_outlined,
            title: AppStrings.exportData,
            onTap: () => _export(context, ref),
          ),
          SettingsTile(
            icon: Icons.download_outlined,
            title: AppStrings.importData,
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }
}
