import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/app_lock/screens/auth_screen.dart';
import '../features/app_lock/screens/lock_setup_screen.dart';
import '../features/google_sign_in/providers/auth_provider.dart';
import '../features/google_sign_in/screens/google_sign_in_screen.dart';
import '../features/onboarding/screens/intro_onboarding_screen.dart';
import '../features/wallet_currency/screens/wallet_currency_setup_screen.dart';
import '../providers/database_provider.dart';
import '../views/app_shell.dart';

part 'app_startup.g.dart';

/// Startup failures are established before `runApp` and remain independent of
/// theme rebuilds and router construction.
abstract final class AppStartupConfiguration {
  static String? startupError;
}

/// The only state machine that selects the application's startup destination.
enum AppFlow { onboarding, login, walletSetup, securitySetup, lockScreen, dashboard }

@Riverpod(keepAlive: true)
class AppStartupController extends _$AppStartupController {
  @override
  Future<AppFlow> build() async {
    final storage = ref.read(secureStorageProvider);
    if (!await storage.hasSeenIntroOnboarding()) return AppFlow.onboarding;

    final authStatus = await ref.watch(authControllerProvider.future);
    if (authStatus != AuthStatus.authenticated && authStatus != AuthStatus.pinLocked) {
      return AppFlow.login;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.isEmpty) return AppFlow.login;

    final syncRepository = ref.read(syncRepositoryProvider);
    // A newly signed-in account may have its wallet only in Firestore. Bring
    // its wallet records into the local-first store before making the flow
    // decision; offline starts retain their already-local wallet state.
    await syncRepository.reconcileWithRemote(user.uid);
    final hasWallet = await syncRepository.hasWalletForUser(user.uid);
    if (!hasWallet) return AppFlow.walletSetup;

    if (await storage.isSecuritySetupPending(user.uid)) {
      return AppFlow.securitySetup;
    }

    return authStatus == AuthStatus.pinLocked ? AppFlow.lockScreen : AppFlow.dashboard;
  }
}

/// Displays exactly one screen from [AppFlow]. It owns no startup decisions.
class AppStartupScreen extends ConsumerWidget {
  const AppStartupScreen({super.key});
  static bool _nativeSplashRemoved = false;

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => FlutterNativeSplash.remove());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupError = AppStartupConfiguration.startupError;
    if (startupError != null) {
      _removeNativeSplash();
      return _StartupError(
        message: startupError,
        onRetry: () {
          AppStartupConfiguration.startupError = null;
          ref.invalidate(appStartupControllerProvider);
        },
      );
    }

    final startup = ref.watch(appStartupControllerProvider);
    return startup.when(
      loading: () => const _StartupLoading(),
      error: (_, _) {
        _removeNativeSplash();
        return _StartupError(
          message: 'Unable to restore your app session. Please try again.',
          onRetry: () => ref.invalidate(appStartupControllerProvider),
        );
      },
      data: (flow) {
        _removeNativeSplash();
        return switch (flow) {
          AppFlow.onboarding => const IntroOnboardingScreen(),
          AppFlow.login => const GoogleSignInScreen(),
          AppFlow.walletSetup => const WalletCurrencySetupScreen(),
          AppFlow.securitySetup => const LockSetupScreen(),
          AppFlow.lockScreen => const AuthScreen(),
          AppFlow.dashboard => const AppShell(),
        };
      },
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
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
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}
