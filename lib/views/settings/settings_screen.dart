import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import 'widgets/settings_currency_section.dart';
import 'widgets/settings_data_section.dart';
import 'widgets/settings_security_section.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_theme_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
              ),
        title: Text(
          AppStrings.settings,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SettingsSection(
              title: AppStrings.theme,
              child: SettingsThemeSection(),
            ),
            const SizedBox(height: 18),
            const SettingsSection(
              title: AppStrings.security,
              child: SettingsSecuritySection(),
            ),
            const SizedBox(height: 18),
            const SettingsSection(
              title: 'Currency',
              child: SettingsCurrencySection(),
            ),
            const SizedBox(height: 18),
            const SettingsSection(
              title: 'Data',
              child: SettingsDataSection(),
            ),
          ],
        ),
      ),
    );
  }
}
