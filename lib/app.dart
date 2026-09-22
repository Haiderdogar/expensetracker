import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_startup.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, this.startupError});

  final String? startupError;
  static bool _startupConfigurationInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_startupConfigurationInitialized) {
      AppStartupConfiguration.startupError = startupError;
      _startupConfigurationInitialized = true;
    }
    return const _AppThemeWrapper();
  }
}

class _AppThemeWrapper extends ConsumerWidget {
  const _AppThemeWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(themeModeControllerProvider);
    final themeMode = switch (selectedMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // A stable router means theme changes cannot restart app navigation.
      routerConfig: appRouter,
    );
  }
}
