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

enum GoogleSignInResult { success, cancelled, configurationError, failed }

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
  bool _hasLoggedInThisSession = false;

  /// True only after the user has pressed Login successfully in this process.
  /// A Firebase session restored at startup deliberately does not set this.
  bool get hasLoggedInThisSession => _hasLoggedInThisSession;

  @override
  Future<AuthStatus> build() async {
    final user = await ref.watch(authStateChangesProvider.future);
    if (user == null) {
      return AuthStatus.unauthenticated;
    }

    await ref.read(databaseHelperProvider).ensureUserInitialized(user.uid);

    final syncRepo = ref.read(syncRepositoryProvider);
    syncRepo.initConnectivityListener(() => user.uid);
    unawaited(_reconcileAndRefresh(user.uid));

    // A restored Firebase session still goes through the Google login gate.
    // The configured local lock is checked after that successful login (or
    // when the app resumes from the background).
    return AuthStatus.authenticated;
  }

  Future<void> _reconcileAndRefresh(
    String userId, {
    bool preferLocal = false,
  }) async {
    await ref
        .read(syncRepositoryProvider)
        .reconcileWithRemote(userId, preferLocal: preferLocal);
    ref.read(localDataEpochProvider.notifier).bump();
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    final wasGuest = state.value == AuthStatus.guest;
    state = const AsyncData(AuthStatus.loading);
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate()
          .timeout(const Duration(seconds: 30));
      final String? idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));
      final user = userCredential.user;
      if (user != null) {
        if (wasGuest) {
          await ref.read(syncRepositoryProvider).migrateGuestData(user.uid);
        }
        final database = ref.read(databaseHelperProvider);
        await database.ensureUserInitialized(user.uid);
        await database.saveGoogleProfile(
          userId: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoURL,
        );
        // A Google session authenticates the account, but it must not bypass
        // an existing local app lock. The lock screen is the next gate for
        // returning users; first-time users have no configured lock yet.
        final hasConfiguredLock = await ref
            .read(secureStorageProvider)
            .hasConfiguredPinLock();
        final syncRepo = ref.read(syncRepositoryProvider);
        syncRepo.initConnectivityListener(() => user.uid);
        unawaited(_reconcileAndRefresh(user.uid, preferLocal: wasGuest));
        _hasLoggedInThisSession = true;
        state = AsyncData(
          hasConfiguredLock ? AuthStatus.pinLocked : AuthStatus.authenticated,
        );
        return GoogleSignInResult.success;
      }

      state = const AsyncData(AuthStatus.unauthenticated);
      return GoogleSignInResult.failed;
    } on GoogleSignInException catch (e) {
      final isConfigurationError =
          e.code == GoogleSignInExceptionCode.clientConfigurationError;
      final isCancellation = e.code.toString().toLowerCase().contains('cancel');
      final message = isConfigurationError
          ? 'Google Sign-In is not configured.'
          : isCancellation
          ? 'Google sign-in was cancelled.'
          : 'Google sign-in failed: $e';
      debugPrint('[AuthController] $message');
      final current = FirebaseAuth.instance.currentUser;
      state = AsyncData(
        current != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      );
      return isConfigurationError
          ? GoogleSignInResult.configurationError
          : isCancellation
          ? GoogleSignInResult.cancelled
          : GoogleSignInResult.failed;
    } catch (e) {
      debugPrint('[AuthController] Google sign-in failed: $e');
      if (wasGuest) {
        try {
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn.instance.signOut();
        } catch (cleanupError) {
          debugPrint(
            '[AuthController] Failed to restore guest session: $cleanupError',
          );
        }
        state = const AsyncData(AuthStatus.guest);
      } else {
        state = const AsyncData(AuthStatus.unauthenticated);
      }
      return GoogleSignInResult.failed;
    }
  }

  /// Continue without contacting Firebase or creating an anonymous account.
  /// The local guest partition is initialized immediately so a wallet exists
  /// before onboarding or any subsequent data entry.
  Future<void> continueAsGuest() async {
    state = const AsyncLoading();
    try {
      await ref
          .read(databaseHelperProvider)
          .ensureUserInitialized('default_user');
      state = const AsyncData(AuthStatus.guest);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _backgroundedAt = null;
    _hasLoggedInThisSession = false;
    ref.read(syncRepositoryProvider).dispose();
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

    await storage.deletePin();
    await storage.setBiometricEnabled(false);

    ref.invalidate(pinEnabledProvider);
    ref.invalidate(biometricEnabledProvider);
    state = const AsyncData(AuthStatus.authenticated);
    return true;
  }

  Future<void> lock() async {
    final storage = ref.read(secureStorageProvider);
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
      state = const AsyncData(AuthStatus.pinLocked);
    }
  }

  Future<void> logout() async {
    await signOut();
  }

  Future<void> logoutAndReset() async {
    if (state.value == AuthStatus.guest) {
      await ref.read(databaseHelperProvider).clearGuestData();
    }
    await signOut();
  }

  Future<void> discardGuestDataAndSignOut() async {
    await ref.read(databaseHelperProvider).clearGuestData();
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
