import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/authentication/session/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'views/app_shell.dart';
import 'features/authentication/google/google_sign_in_screen.dart';
import 'features/authentication/lock/auth_screen.dart';
import 'features/authentication/lock/lock_setup_screen.dart';
import 'features/intro_onboarding/intro_onboarding_screen.dart';
import 'features/wallet_setup/wallet_setup_screen.dart';

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
          // Once intro onboarding is complete, the only valid destination
          // before account state resolves is the Google login screen.
          loading: () => const GoogleSignInScreen(),
          error: (_, __) => _BootstrapError(
            message: 'Unable to restore authentication. Please try again.',
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
          data: (status) {
            if (status == AuthStatus.pinLocked) return const AuthScreen();
            if (status == AuthStatus.authenticated) {
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
    final walletsAsync = ref.watch(walletsProvider);
    return walletsAsync.when(
      // Wallet setup is the required next step after a successful login when
      // the wallet query has not completed yet.
      loading: () => const OnboardingScreen(),
      error: (_, __) => _BootstrapError(
        message: 'Unable to load your account setup. Please try again.',
        onRetry: () => ref.invalidate(walletsProvider),
      ),
      data: (wallets) {
        // A wallet is created only by the Get Started action. The existence
        // of a wallet is therefore the durable completion signal for this
        // part of the navigation architecture.
        if (wallets.isEmpty) return const OnboardingScreen();

        // Wallet setup must complete before app-lock handling.
        final authAsync = ref.watch(authControllerProvider);
        if (authAsync.value == AuthStatus.pinLocked) {
          return const AuthScreen();
        }

        final lockPromptAsync = ref.watch(lockPromptCompletedProvider);
        return lockPromptAsync.when(
          loading: () => const LockSetupScreen(),
          error: (_, __) => _BootstrapError(
            message: 'Unable to load security settings. Please try again.',
            onRetry: () => ref.invalidate(lockPromptCompletedProvider),
          ),
          data: (lockPromptComplete) =>
              lockPromptComplete ? const AppShell() : const LockSetupScreen(),
        );
      },
    );
  }
}

class _BootstrapLoading extends StatelessWidget {
  const _BootstrapLoading();

  @override
  Widget build(BuildContext context) {
    // Keep the native splash visible while local app state is being read.
    return const SizedBox.shrink();
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
              Text(message, textAlign: TextAlign.center),
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
        if (status == AuthStatus.authenticated) {
          return const _PostLoginFlow();
        }
        return const GoogleSignInScreen();
      },
    );
  }
}
