import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'views/app_shell.dart';
import 'views/auth/auth_screen.dart';
import 'views/auth/google_sign_in_screen.dart';
import 'views/auth/lock_setup_screen.dart';
import 'views/onboarding/intro_onboarding_screen.dart';
import 'views/onboarding/onboarding_screen.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
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
    final introSeenAsync = ref.watch(introOnboardingSeenProvider);
    return introSeenAsync.when(
      loading: () => const _BootstrapLoading(),
      error: (error, _) => _BootstrapError(error: error),
      data: (hasSeenIntro) {
        if (!hasSeenIntro) return const IntroOnboardingScreen();

        final onboardingAsync = ref.watch(onboardingCompleteProvider);
        return onboardingAsync.when(
          loading: () => const _BootstrapLoading(),
          error: (error, _) => _BootstrapError(error: error),
          data: (complete) {
            if (!complete) return const OnboardingScreen();

        final authAsync = ref.watch(authControllerProvider);
        return authAsync.when(
          loading: () => const _BootstrapLoading(),
          error: (error, _) => _BootstrapError(error: error),
          data: (status) {
            if (status == AuthStatus.unauthenticated) {
              return const GoogleSignInScreen();
            }
            if (status == AuthStatus.pinLocked) return const AuthScreen();
            if (status == AuthStatus.guest) return const AppShell();

                final lockPromptAsync = ref.watch(lockPromptCompletedProvider);
                return lockPromptAsync.when(
                  loading: () => const _BootstrapLoading(),
                  error: (error, _) => _BootstrapError(error: error),
                  data: (prompted) {
                    if (!prompted && status != AuthStatus.unauthenticated) {
                      return const LockSetupScreen();
                    }
                    return const AppShell();
                  },
                );
          },
        );
          },
        );
      },
    );
  }
}

class _BootstrapLoading extends StatelessWidget {
  const _BootstrapLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ColoredBox(color: Colors.transparent));
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to start the app. Please try again.\n\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authControllerProvider);

    return authAsync.when(
      loading: () => Scaffold(
        body: Container(color: Theme.of(context).scaffoldBackgroundColor),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (status) {
        return switch (status) {
          AuthStatus.authenticated => const AppShell(),
          AuthStatus.unauthenticated => const GoogleSignInScreen(),
          AuthStatus.guest => const AppShell(),
          AuthStatus.pinLocked => const AuthScreen(),
          AuthStatus.needsPinSetup ||
          AuthStatus.loading => const GoogleSignInScreen(),
        };
      },
    );
  }
}
