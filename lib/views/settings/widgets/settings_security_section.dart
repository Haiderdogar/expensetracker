import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../settings_actions.dart';
import 'settings_tile.dart';

class SettingsSecuritySection extends StatelessWidget {
  const SettingsSecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [SettingsPinTile(), SettingsBiometricTile()]);
  }
}

class SettingsPinTile extends StatelessWidget {
  const SettingsPinTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => ref.watch(pinEnabledProvider).when(
        loading: () => const ListTile(leading: CircularProgressIndicator(), title: Text('PIN lock')),
        error: (error, _) => ListTile(title: Text(error.toString())),
        data: (enabled) => SettingsTile(
          icon: Icons.pin_outlined,
          title: enabled ? AppStrings.changePin : AppStrings.enablePinLock,
          trailing: Switch(value: enabled, onChanged: (value) => SettingsActions.togglePin(context, ref, value)),
          onTap: () => SettingsActions.editPin(context, ref, enabled),
        ),
      ),
    );
  }
}

class SettingsBiometricTile extends StatelessWidget {
  const SettingsBiometricTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => ref.watch(biometricEnabledProvider).when(
        loading: () => const ListTile(leading: CircularProgressIndicator(), title: Text(AppStrings.enableBiometric)),
        error: (error, _) => ListTile(title: Text(error.toString())),
        data: (enabled) => SettingsTile(
          icon: Icons.fingerprint_rounded,
          title: AppStrings.enableBiometric,
          trailing: Switch(value: enabled, onChanged: (value) => SettingsActions.toggleBiometric(context, ref, value)),
          onTap: () => SettingsActions.toggleBiometric(context, ref, !enabled),
        ),
      ),
    );
  }
}
