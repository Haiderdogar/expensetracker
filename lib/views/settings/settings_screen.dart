import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/global_keys.dart';
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
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text(AppStrings.settings),
      ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Manage categories', style: Theme.of(context).textTheme.titleSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final nameController = TextEditingController();
                    String type = 'expense';
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Add category'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Name')),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Radio<String>(value: 'expense', groupValue: type, onChanged: (v) => type = v ?? 'expense'),
                                const Text('Expense'),
                                const SizedBox(width: 12),
                                Radio<String>(value: 'income', groupValue: type, onChanged: (v) => type = v ?? 'income'),
                                const Text('Income'),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Save')),
                        ],
                      ),
                    );
                    if (result != true) return;
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    try {
                      await ref.read(categoriesProvider.notifier).create(
                        name: name,
                        type: type,
                        icon: type == 'income' ? 'work' : 'shopping_bag',
                        color: type == 'income' ? '#2ECC71' : '#FF6B6B',
                      );
                      ref.invalidate(categoriesProvider);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add category'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer(builder: (cctx, cref, _) {
              final all = cref.watch(categoriesProvider);
              return all.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (cats) {
                  if (cats.isEmpty) return const Text('No categories yet');
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cats.map((c) {
                      return InputChip(
                        label: Text('${c.name} (${c.type})'),
                        onPressed: () {},
                        onDeleted: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dctx) => AlertDialog(
                              title: const Text('Delete category'),
                              content: Text('Delete "${c.name}"? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await cref.read(categoriesProvider.notifier).delete(c.id);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              );
            }),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Currency', style: Theme.of(context).textTheme.titleSmall),
          ),
          FutureBuilder<String>(
            future: ref.read(databaseHelperProvider).getCurrencySymbol(),
            builder: (ctx, snap) {
              final current = snap.data ?? '\$';
              return ListTile(
                leading: const Icon(Icons.money),
                title: Text('Currency: $current'),
                trailing: TextButton(
                  onPressed: () async {
                    final chosen = await showDialog<String>(
                      context: context,
                      builder: (dctx) {
                        final controller = TextEditingController();
                        final options = ['\$', 'PKR', 'USD', 'AED', 'SAR', 'JPY'];
                        return AlertDialog(
                          title: const Text('Select currency'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                spacing: 8,
                                children: options.map((o) => ElevatedButton(onPressed: () => Navigator.of(dctx).pop(o), child: Text(o))).toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller,
                                decoration: const InputDecoration(hintText: 'Custom (PKR, USD, etc.)'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dctx).pop(null), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(dctx).pop(controller.text.trim().isEmpty ? null : controller.text.trim()), child: const Text('Save')),
                          ],
                        );
                      },
                    );
                    if (chosen == null || chosen.isEmpty) return;
                    try {
                      await ref.read(databaseHelperProvider).setCurrencySymbol(chosen);
                      ref.invalidate(currencySymbolProvider);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Currency updated')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Text('Change'),
                ),
              );
            },
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
