import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/theme_provider.dart';
import 'settings_tile.dart';

class SettingsThemeSection extends StatelessWidget {
  const SettingsThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(themeModeControllerProvider);
        return Column(
          children: AppThemeMode.values.map((mode) {
            final (icon, title) = switch (mode) {
              AppThemeMode.light => (Icons.light_mode_outlined, AppStrings.lightMode),
              AppThemeMode.dark => (Icons.dark_mode_outlined, AppStrings.darkMode),
              AppThemeMode.system => (Icons.brightness_auto_outlined, AppStrings.systemMode),
            };
            return SettingsTile(
              icon: icon,
              title: title,
              trailing: Radio<AppThemeMode>(
                value: mode,
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) ref.read(themeModeControllerProvider.notifier).setMode(value);
                },
              ),
              onTap: () => ref.read(themeModeControllerProvider.notifier).setMode(mode),
            );
          }).toList(),
        );
      },
    );
  }
}
