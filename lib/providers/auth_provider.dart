import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database_provider.dart';

part 'auth_provider.g.dart';

enum AuthStatus { loading, unauthenticated, authenticated, needsPinSetup }

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AuthStatus> build() async {
    final storage = ref.read(secureStorageProvider);
    final hasPin = await storage.hasPin();
    final pinEnabled = await storage.isPinEnabled();
    if (hasPin && pinEnabled) return AuthStatus.unauthenticated;
    return AuthStatus.authenticated;
  }

  Future<bool> verifyPin(String pin) async {
    final storage = ref.read(secureStorageProvider);
    final valid = await storage.verifyPin(pin);
    if (valid) {
      state = const AsyncData(AuthStatus.authenticated);
    }
    return valid;
  }

  Future<void> setupPin(String pin) async {
    final storage = ref.read(secureStorageProvider);
    await storage.savePinHash(pin);
    await storage.setPinEnabled(true);
    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<void> lock() async {
    final storage = ref.read(secureStorageProvider);
    final hasPin = await storage.hasPin();
    final pinEnabled = await storage.isPinEnabled();
    state = AsyncData(
      hasPin && pinEnabled
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
    );
  }

  Future<void> logout() => lock();

  Future<bool> authenticateWithBiometric() async {
    final storage = ref.read(secureStorageProvider);
    final enabled = await storage.isBiometricEnabled();
    if (!enabled) return false;

    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    if (!canCheck) return false;

    final success = await auth.authenticate(
      localizedReason: 'Unlock Expense Tracker',
      biometricOnly: true,
    );

    if (success) {
      state = const AsyncData(AuthStatus.authenticated);
    }
    return success;
  }
}

@riverpod
Future<bool> pinEnabled(Ref ref) async {
  return ref.read(secureStorageProvider).isPinEnabled();
}

@riverpod
Future<bool> biometricEnabled(Ref ref) async {
  return ref.read(secureStorageProvider).isBiometricEnabled();
}

@riverpod
Future<bool> onboardingComplete(Ref ref) async {
  return ref.read(databaseHelperProvider).isOnboardingComplete();
}

@riverpod
Future<String> currencySymbol(Ref ref) async {
  return ref.read(databaseHelperProvider).getCurrencySymbol();
}
