import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_startup.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/updates/flexible_update_coordinator.dart';

class ExpenseeApp extends StatelessWidget {
  const ExpenseeApp({super.key, this.startupError});

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

typedef ExpenseTrackerApp = ExpenseeApp;

class _AppThemeWrapper extends ConsumerStatefulWidget {
  const _AppThemeWrapper();

  @override
  ConsumerState<_AppThemeWrapper> createState() => _AppThemeWrapperState();
}

class _AppThemeWrapperState extends ConsumerState<_AppThemeWrapper> {
  final FlexibleUpdateCoordinator _updateCoordinator =
      FlexibleUpdateCoordinator();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_updateCoordinator.initialize());
    });
  }

  @override
  void dispose() {
    unawaited(_updateCoordinator.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      scaffoldMessengerKey: _updateCoordinator.scaffoldMessengerKey,
      // A stable router means theme changes cannot restart app navigation.
      routerConfig: appRouter,
    );
  }
}
