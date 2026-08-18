import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'views/app_shell.dart';
import 'views/auth/auth_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'widgets/shimmer_loader.dart';

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(themeModeControllerProvider);
    final themeMode = switch (selectedMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingCompleteProvider);

    return onboardingAsync.when(
      loading: () => Scaffold(
                    body: Container(color: Theme.of(context).scaffoldBackgroundColor),
            ),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (complete) {
        if (!complete) return const OnboardingScreen();
        return const AuthGate();
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authControllerProvider);

    return authAsync.when(
      loading: () => Scaffold(body: Container(color: Theme.of(context).scaffoldBackgroundColor)),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (status) {
        return switch (status) {
          AuthStatus.authenticated => const AppShell(),
          AuthStatus.needsPinSetup => const AuthScreen(isSetup: true),
          AuthStatus.unauthenticated => const AuthScreen(),
          AuthStatus.loading => const Scaffold(
                      body: SizedBox.shrink(),
          ),
        };
      },
    );
  }
}
