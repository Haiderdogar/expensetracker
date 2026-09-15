import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database_provider.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  loading,
  unauthenticated, // Not signed in with Google
  authenticated, // Signed in and unlocked
  guest, // Continuing without creating an account
  pinLocked, // Signed in, but locked behind local PIN
  needsPinSetup,
}

const _resumeLockAfter = Duration(seconds: 30);

@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (e) {
    debugPrint('[authStateChanges] Firebase unavailable: $e');
    return Stream<User?>.value(null);
  }
}

@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  return ref.watch(authStateChangesProvider).value;
}

@Riverpod(keepAlive: true)
String currentUserId(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid ?? 'default_user';
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  DateTime? _backgroundedAt;
  bool _pinUnlocked = false;

  @override
  Future<AuthStatus> build() async {
    final user = await ref.watch(authStateChangesProvider.future);
    if (user == null) {
      _pinUnlocked = false;
      return AuthStatus.unauthenticated;
    }

    await ref.read(databaseHelperProvider).ensureUserInitialized(user.uid);

    final syncRepo = ref.read(syncRepositoryProvider);
    syncRepo.initConnectivityListener(() => user.uid);
    unawaited(_reconcileAndRefresh(user.uid));

    // Check optional local PIN lock
    final storage = ref.read(secureStorageProvider);
    final hasPin = await storage.hasConfiguredPinLock();
    if (hasPin && !_pinUnlocked) {
      return AuthStatus.pinLocked;
    }

    return AuthStatus.authenticated;
  }

  Future<void> _reconcileAndRefresh(String userId) async {
    await ref.read(syncRepositoryProvider).reconcileWithRemote(userId);
    ref.read(localDataEpochProvider.notifier).bump();
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final String? idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user != null) {
        await ref.read(databaseHelperProvider).ensureUserInitialized(user.uid);
        _pinUnlocked = true;
        final syncRepo = ref.read(syncRepositoryProvider);
        syncRepo.initConnectivityListener(() => user.uid);
        unawaited(_reconcileAndRefresh(user.uid));
        state = const AsyncData(AuthStatus.authenticated);
        return true;
      }

      state = const AsyncData(AuthStatus.unauthenticated);
      return false;
    } on GoogleSignInException catch (e) {
      final message = e.code == GoogleSignInExceptionCode.clientConfigurationError
          ? 'Google Sign-In is not configured. Regenerate google-services.json '
                'after enabling Google Auth and adding this app\'s SHA-1.'
          : 'Google sign-in cancelled or failed: $e';
      debugPrint('[AuthController] $message');
      final current = FirebaseAuth.instance.currentUser;
      state = AsyncData(
        current != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      );
      return false;
    } catch (e) {
      debugPrint('[AuthController] Google sign-in failed: $e');
      state = const AsyncData(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// Continue without contacting Firebase or creating an anonymous account.
  void continueAsGuest() {
    state = const AsyncData(AuthStatus.guest);
  }

  Future<void> signOut() async {
    _backgroundedAt = null;
    _pinUnlocked = false;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    state = const AsyncData(AuthStatus.unauthenticated);
  }

  Future<bool> checkPin(String pin) async {
    final storage = ref.read(secureStorageProvider);
    if (!await storage.hasConfiguredPinLock()) return false;
    return storage.verifyPin(pin);
  }

  Future<bool> verifyPin(String pin) async {
    final valid = await checkPin(pin);
    if (valid) {
      _pinUnlocked = true;
      state = const AsyncData(AuthStatus.authenticated);
    }
    return valid;
  }

  Future<void> setupPin(String pin) async {
    final storage = ref.read(secureStorageProvider);
    await storage.savePinHash(pin);
    await storage.setPinEnabled(true);
    await storage.setLockPromptCompleted(true);
    _pinUnlocked = true;
    ref.invalidate(pinEnabledProvider);
    ref.invalidate(lockPromptCompletedProvider);
    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<void> skipLockSetup() async {
    final storage = ref.read(secureStorageProvider);
    await storage.setLockPromptCompleted(true);
    _pinUnlocked = true;
    ref.invalidate(lockPromptCompletedProvider);
    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<bool> disablePin({String? currentPin}) async {
    final storage = ref.read(secureStorageProvider);
    if (currentPin != null && !await storage.verifyPin(currentPin)) {
      return false;
    }

    await storage.deletePin();
    await storage.setBiometricEnabled(false);

    ref.invalidate(pinEnabledProvider);
    ref.invalidate(biometricEnabledProvider);
    state = const AsyncData(AuthStatus.authenticated);
    return true;
  }

  Future<void> lock() async {
    final storage = ref.read(secureStorageProvider);
    _pinUnlocked = false;
    state = AsyncData(
      await storage.hasConfiguredPinLock()
          ? AuthStatus.pinLocked
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final storage = ref.read(secureStorageProvider);
    if (await storage.hasConfiguredPinLock()) {
      _pinUnlocked = false;
      state = const AsyncData(AuthStatus.pinLocked);
    }
  }

  Future<void> logout() async {
    await signOut();
  }

  Future<void> logoutAndReset() async {
    await signOut();
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
      if (biometrics.contains(BiometricType.strong)) {
        return BiometricType.strong;
      }
      if (biometrics.contains(BiometricType.weak)) {
        return BiometricType.weak;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

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
    if (!await storage.hasConfiguredBiometricLock()) return false;

    final success = await promptBiometric(reason: 'Unlock Expense Tracker');
    if (success) {
      _pinUnlocked = true;
      state = const AsyncData(AuthStatus.authenticated);
    }
    return success;
  }

  Future<bool> enableBiometricUnlock() async {
    final storage = ref.read(secureStorageProvider);
    if (!await storage.hasConfiguredPinLock()) return false;
    final available = await isBiometricAvailable();
    if (!available) return false;
    await storage.setBiometricEnabled(true);
    ref.invalidate(biometricEnabledProvider);
    return true;
  }
}

@riverpod
Future<bool> lockPromptCompleted(Ref ref) async {
  return ref.read(secureStorageProvider).isLockPromptCompleted();
}

@riverpod
Future<bool> introOnboardingSeen(Ref ref) async {
  return ref.read(secureStorageProvider).hasSeenIntroOnboarding();
}

@riverpod
Future<bool> pinEnabled(Ref ref) async {
  return ref.read(secureStorageProvider).hasConfiguredPinLock();
}

@riverpod
Future<bool> biometricEnabled(Ref ref) async {
  return ref.read(secureStorageProvider).hasConfiguredBiometricLock();
}

@riverpod
Future<bool> onboardingComplete(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(databaseHelperProvider).isOnboardingComplete(userId);
}

@riverpod
Future<String> currencySymbol(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(databaseHelperProvider).getCurrencySymbol(userId);
}
