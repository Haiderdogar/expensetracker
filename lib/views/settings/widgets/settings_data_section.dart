import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../settings_actions.dart';
import 'settings_tile.dart';

class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final colors = Theme.of(context).colorScheme;
        return Column(
          children: [
            SettingsTile(
              icon: Icons.upload_outlined,
              title: AppStrings.exportData,
              accentColor: colors.primary.withValues(alpha: 0.10),
              onTap: () => SettingsActions.exportData(context, ref),
            ),
            SettingsTile(
              icon: Icons.download_outlined,
              title: AppStrings.importData,
              accentColor: colors.secondaryContainer,
              onTap: () => SettingsActions.importData(context, ref),
            ),
          ],
        );
      },
    );
  }
}
