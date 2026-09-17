import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

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

  static bool _nativeSplashRemoved = false;

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final introSeenAsync = ref.watch(introOnboardingSeenProvider);
    return introSeenAsync.when(
      loading: () => const _BootstrapLoading(),
      error: (_, __) {
        _removeNativeSplash();
        return _BootstrapError(
          onRetry: () {
            ref.invalidate(introOnboardingSeenProvider);
            ref.invalidate(authControllerProvider);
          },
        );
      },
      data: (hasSeenIntro) {
        _removeNativeSplash();
        // This secure-storage flag is the source of truth for whether the
        // first-run experience has finished.  It intentionally does not
        // depend on a Firebase user or the local database, so guests and
        // signed-in users get the same one-time onboarding behaviour.
        if (!hasSeenIntro) return const IntroOnboardingScreen();

        final authAsync = ref.watch(authControllerProvider);
        return authAsync.when(
          loading: () => const _BootstrapLoading(),
          error: (_, __) => _BootstrapError(
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
          data: (status) {
            if (status == AuthStatus.pinLocked) return const AuthScreen();
            if (status == AuthStatus.authenticated &&
                ref
                    .read(authControllerProvider.notifier)
                    .hasLoggedInThisSession) {
              return const _PostLoginFlow();
            }
            if (status == AuthStatus.guest) return const _PostLoginFlow();
            // A restored Firebase session must still pass through Login on
            // every new app launch. Only a successful login in this process
            // (or an explicit guest choice) opens the app shell.
            return const GoogleSignInScreen();
          },
        );
      },
    );
  }
}

/// Runs once after a successful login or guest choice:
/// wallet/currency setup, then optional local app-lock setup, then the main app.
class _PostLoginFlow extends ConsumerWidget {
  const _PostLoginFlow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingCompleteProvider);
    return onboardingAsync.when(
      loading: () => const _BootstrapLoading(),
      error: (_, __) => _BootstrapError(
        onRetry: () => ref.invalidate(onboardingCompleteProvider),
      ),
      data: (onboardingComplete) {
        if (!onboardingComplete) return const OnboardingScreen();

        final lockPromptAsync = ref.watch(lockPromptCompletedProvider);
        return lockPromptAsync.when(
          loading: () => const _BootstrapLoading(),
          error: (_, __) => _BootstrapError(
            onRetry: () => ref.invalidate(lockPromptCompletedProvider),
          ),
          data: (lockPromptComplete) => lockPromptComplete
              ? const AppShell()
              : const LockSetupScreen(),
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
  const _BootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unable to start the app. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
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
        if (status == AuthStatus.pinLocked) return const AuthScreen();
        if (status == AuthStatus.guest) return const _PostLoginFlow();
        if (status == AuthStatus.authenticated &&
            ref
                .read(authControllerProvider.notifier)
                .hasLoggedInThisSession) {
          return const _PostLoginFlow();
        }
        return const GoogleSignInScreen();
      },
    );
  }
}
