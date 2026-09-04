import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database_provider.dart';

part 'auth_provider.g.dart';

enum AuthStatus { loading, unauthenticated, authenticated, needsPinSetup }

const _resumeLockAfter = Duration(seconds: 30);

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  DateTime? _backgroundedAt;

  @override
  Future<AuthStatus> build() async {
    final storage = ref.read(secureStorageProvider);
    final hasPin = await storage.hasPin();
    final pinEnabled = await storage.isPinEnabled();
    if (hasPin && pinEnabled) return AuthStatus.unauthenticated;
    return AuthStatus.authenticated;
  }

  Future<bool> checkPin(String pin) async {
    return ref.read(secureStorageProvider).verifyPin(pin);
  }

  Future<bool> verifyPin(String pin) async {
    final valid = await checkPin(pin);
    if (valid) {
      state = const AsyncData(AuthStatus.authenticated);
    }
    return valid;
  }

  Future<void> setupPin(String pin) async {
    final storage = ref.read(secureStorageProvider);
    await storage.savePinHash(pin);
    await storage.setPinEnabled(true);
    await storage.setLockPromptCompleted(true);
    ref.invalidate(pinEnabledProvider);
    ref.invalidate(lockPromptCompletedProvider);
    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<void> skipLockSetup() async {
    final storage = ref.read(secureStorageProvider);
    await storage.setLockPromptCompleted(true);
    ref.invalidate(lockPromptCompletedProvider);
    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<bool> disablePin({String? currentPin}) async {
    final storage = ref.read(secureStorageProvider);
    if (currentPin != null && !await storage.verifyPin(currentPin)) {
      return false;
    }

    // Remove stored PIN entirely to avoid leaving stale hashes on device.
    // deletePin also clears the pin enabled flag.
    await storage.deletePin();

    // Ensure biometric flag is cleared as well.
    await storage.setBiometricEnabled(false);

    ref.invalidate(pinEnabledProvider);
    ref.invalidate(biometricEnabledProvider);
    state = const AsyncData(AuthStatus.authenticated);
    return true;
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

  void onAppBackgrounded() {
    _backgroundedAt = DateTime.now();
  }

  Future<void> onAppResumed() async {
    final started = _backgroundedAt;
    _backgroundedAt = null;
    if (started == null) return;
    if (DateTime.now().difference(started) < _resumeLockAfter) return;
    if (state.value == AuthStatus.unauthenticated) return;
    await lock();
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearAll();
    ref.invalidate(pinEnabledProvider);
    ref.invalidate(biometricEnabledProvider);
    ref.invalidate(lockPromptCompletedProvider);
    state = const AsyncData(AuthStatus.unauthenticated);
  }

  Future<bool> isBiometricAvailable() async {
    return (await preferredBiometric()) != null;
  }

  Future<BiometricType?> preferredBiometric() async {
    final auth = LocalAuthentication();
    try {
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      final biometrics = await auth.getAvailableBiometrics();
      if (!supported || !canCheck) return null;
      if (biometrics.contains(BiometricType.face)) return BiometricType.face;
      if (biometrics.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      // Android exposes enrolled sensors as weak/strong classifications,
      // rather than identifying fingerprint or face directly.
      if (biometrics.contains(BiometricType.strong))
        return BiometricType.strong;
      if (biometrics.contains(BiometricType.weak)) return BiometricType.weak;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Prompts only an enrolled face or fingerprint biometric.
  Future<bool> promptBiometric({
    String reason = 'Unlock Expense Tracker',
  }) async {
    if (await preferredBiometric() == null) return false;

    final auth = LocalAuthentication();
    try {
      return await auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    final storage = ref.read(secureStorageProvider);
    final enabled = await storage.isBiometricEnabled();
    if (!enabled) return false;

    final success = await promptBiometric(reason: 'Unlock Expense Tracker');
    if (success) {
      state = const AsyncData(AuthStatus.authenticated);
    }
    return success;
  }

  Future<bool> enableBiometricUnlock() async {
    final available = await isBiometricAvailable();
    if (!available) return false;
    await ref.read(secureStorageProvider).setBiometricEnabled(true);
    ref.invalidate(biometricEnabledProvider);
    return true;
  }
}

final lockPromptCompletedProvider = FutureProvider<bool>((ref) async {
  return ref.read(secureStorageProvider).isLockPromptCompleted();
});

@riverpod
Future<bool> pinEnabled(Ref ref) async {
  final storage = ref.read(secureStorageProvider);
  return await storage.isPinEnabled() && await storage.hasPin();
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
