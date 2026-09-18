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
  const ExpenseTrackerApp({super.key, this.startupError});

  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return _AppThemeWrapper(startupError: startupError);
  }
}

class _AppThemeWrapper extends ConsumerWidget {
  const _AppThemeWrapper({this.startupError});

  final String? startupError;

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
      home: AppBootstrap(startupError: startupError),
    );
  }
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key, this.startupError});

  final String? startupError;

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
    if (startupError != null) {
      _removeNativeSplash();
      return _BootstrapError(
        message: startupError!,
        onRetry: () => ref.invalidate(authControllerProvider),
      );
    }
    final introSeenAsync = ref.watch(introOnboardingSeenProvider);
    return introSeenAsync.when(
      loading: () => const _BootstrapLoading(),
      error: (_, __) {
        _removeNativeSplash();
        return _BootstrapError(
          message: 'Unable to load onboarding. Please try again.',
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
        // depend on a Firebase user or the local database, so every install
        // gets the same one-time onboarding behaviour.
        if (!hasSeenIntro) return const IntroOnboardingScreen();

        final authAsync = ref.watch(authControllerProvider);
        return authAsync.when(
          loading: () => const _BootstrapLoading(),
          error: (_, __) => _BootstrapError(
            message: 'Unable to restore authentication. Please try again.',
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
          data: (status) {
            if (status == AuthStatus.pinLocked) return const AuthScreen();
            if (status == AuthStatus.loading) {
              return const GoogleSignInScreen();
            }
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
        message: 'Unable to load your account setup. Please try again.',
        onRetry: () => ref.invalidate(onboardingCompleteProvider),
      ),
      data: (onboardingComplete) {
        if (!onboardingComplete) return const OnboardingScreen();

        // A fresh Google login for an existing account authenticates the
        // account first, then requires the configured local lock before the
        // dashboard is exposed.
        final authAsync = ref.watch(authControllerProvider);
        if (authAsync.value == AuthStatus.pinLocked) {
          return const AuthScreen();
        }

        final lockPromptAsync = ref.watch(lockPromptCompletedProvider);
        return lockPromptAsync.when(
          loading: () => const _BootstrapLoading(),
          error: (_, __) => _BootstrapError(
            message: 'Unable to load security settings. Please try again.',
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
  const _BootstrapError({required this.message, required this.onRetry});

  final String message;
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
              Text(
                message,
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
