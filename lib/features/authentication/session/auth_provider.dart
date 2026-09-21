import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/google_sign_in_service.dart';
import '../../../providers/database_provider.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
  guest,
  pinLocked,
  needsPinSetup,
}

enum GoogleSignInResult {
  success,
  cancelled,
  configurationError,
  failed,
  noInternet,
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
  final streamUser = ref.watch(authStateChangesProvider).value;

  if (streamUser != null) {
    return streamUser;
  }

  try {
    return FirebaseAuth.instance.currentUser;
  } catch (_) {
    return null;
  }
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

  bool _isGoogleSignInInProgress = false;

  String? _lastGoogleSignInError;

  String? get lastGoogleSignInError => _lastGoogleSignInError;

  @override
  Future<AuthStatus> build() async {
    final user = await ref.read(authStateChangesProvider.future);

    if (user == null) {
      return AuthStatus.unauthenticated;
    }

    final storage = ref.read(secureStorageProvider);

    final hasValidSession = await storage.hasValidLoginSession(user.uid);

    if (!hasValidSession) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('[AuthController] Firebase sign out failed: $e');
      }

      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('[AuthController] Google sign out failed: $e');
      }

      return AuthStatus.unauthenticated;
    }

    await ref.read(databaseHelperProvider).ensureUserInitialized(user.uid);

    final syncRepo = ref.read(syncRepositoryProvider);

    syncRepo.initConnectivityListener(() => user.uid);

    unawaited(_reconcileAndRefresh(user.uid));

    if (_hasLoggedInThisSession) {
      return AuthStatus.authenticated;
    }

    return AuthStatus.unauthenticated;
  }

  Future<void> _reconcileAndRefresh(
    String userId, {
    bool preferLocal = false,
  }) async {
    try {
      await ref
          .read(syncRepositoryProvider)
          .reconcileWithRemote(userId, preferLocal: preferLocal);

      ref.read(localDataEpochProvider.notifier).bump();
    } catch (e, stackTrace) {
      debugPrint('[AuthController] Sync failed: $e\n$stackTrace');
    }
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    if (_isGoogleSignInInProgress) {
      return GoogleSignInResult.failed;
    }

    _isGoogleSignInInProgress = true;
    _lastGoogleSignInError = null;

    state = const AsyncLoading();

    try {
      /*
       * GoogleSignInService initializes the singleton GoogleSignIn
       * instance before authentication.
       */
      await GoogleSignInService.ensureInitialized();
      debugPrint('[AuthController] Google Sign-In initialized.');

      /*
       * authenticate() is intentionally called only from the
       * button action.
       *
       * On Android this opens Google's native account-selection/
       * authentication UI.
       */
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate()
          .timeout(const Duration(seconds: 30));
      debugPrint(
        '[AuthController] Google account selected: ${googleUser.email}',
      );

      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In did not return an ID token.');
      }

      /*
       * Convert the Google credential into a Firebase credential.
       */
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      debugPrint('[AuthController] Google ID token received.');

      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));

      final user = userCredential.user;

      if (user == null) {
        throw StateError('Firebase did not return a signed-in user.');
      }
      debugPrint(
        '[AuthController] Firebase sign-in completed for ${user.uid}.',
      );

      /*
       * Make sure the local database has the user's partition.
       */
      final database = ref.read(databaseHelperProvider);

      await database.ensureUserInitialized(user.uid);

      /*
       * Save the Google profile locally/in the database.
       */
      await database.saveGoogleProfile(
        userId: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
      );

      /*
       * Store the login session on the local device.
       *
       * Your SecureStorageService stores:
       * - user ID
       * - email
       * - login timestamp
       */
      await ref
          .read(secureStorageProvider)
          .saveLoginSession(userId: user.uid, email: user.email);

      /*
       * Initialize sync after successful authentication.
       */
      final syncRepo = ref.read(syncRepositoryProvider);

      syncRepo.initConnectivityListener(() => user.uid);

      unawaited(_reconcileAndRefresh(user.uid, preferLocal: false));

      /*
       * Mark this process as successfully authenticated.
       */
      _hasLoggedInThisSession = true;

      /*
       * This state change is what causes AppBootstrap to move
       * from GoogleSignInScreen -> _PostLoginFlow.
       */
      state = const AsyncData(AuthStatus.authenticated);

      return GoogleSignInResult.success;
    } on GoogleSignInException catch (e) {
      final isConfigurationError =
          e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError;

      final isCancellation =
          e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted;

      final String message;

      if (isConfigurationError) {
        message =
            'Google Sign-In is not configured correctly. '
            'Please verify Firebase, OAuth client IDs, '
            'package name and SHA-1.';
      } else if (isCancellation) {
        message = 'Google Sign-In was cancelled.';
      } else if (e.code == GoogleSignInExceptionCode.uiUnavailable) {
        message =
            'Google Sign-In is unavailable right now. '
            'Please try again.';
      } else {
        message = 'Google Sign-In failed. Please try again.';
      }

      _lastGoogleSignInError = message;

      debugPrint(
        '[AuthController] Google Sign-In error: '
        '$message (${e.code})',
      );

      state = const AsyncData(AuthStatus.unauthenticated);

      return isConfigurationError
          ? GoogleSignInResult.configurationError
          : isCancellation
          ? GoogleSignInResult.cancelled
          : GoogleSignInResult.failed;
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'operation-not-allowed' =>
          'Google Sign-In is disabled in Firebase Authentication.',

        'invalid-credential' =>
          'Google credentials were rejected. '
              'Please verify your Firebase OAuth configuration.',

        'network-request-failed' => 'A network error prevented Google Sign-In.',

        'account-exists-with-different-credential' =>
          'This email is already linked to another sign-in method.',

        _ =>
          'Firebase could not complete Google Sign-In. '
              'Please try again.',
      };

      _lastGoogleSignInError = message;

      debugPrint(
        '[AuthController] Firebase Auth error: '
        '$message (${e.code})',
      );

      state = const AsyncData(AuthStatus.unauthenticated);

      return e.code == 'operation-not-allowed' || e.code == 'invalid-credential'
          ? GoogleSignInResult.configurationError
          : GoogleSignInResult.failed;
    } on TimeoutException catch (e) {
      const message =
          'Google Sign-In timed out. '
          'Please check your internet connection and try again.';

      _lastGoogleSignInError = message;

      debugPrint('[AuthController] Timeout: $e');

      state = const AsyncData(AuthStatus.unauthenticated);

      return GoogleSignInResult.failed;
    } on StateError catch (e) {
      final message = e.message;

      _lastGoogleSignInError = message.isNotEmpty
          ? message
          : 'Google Sign-In could not be completed.';

      debugPrint('[AuthController] State error: $e');

      state = const AsyncData(AuthStatus.unauthenticated);

      return GoogleSignInResult.failed;
    } catch (e, stackTrace) {
      const message =
          'Google Sign-In failed unexpectedly. '
          'Please try again.';

      _lastGoogleSignInError = message;

      debugPrint('[AuthController] Unexpected error: $e\n$stackTrace');

      state = const AsyncData(AuthStatus.unauthenticated);

      return GoogleSignInResult.failed;
    } finally {
      _isGoogleSignInInProgress = false;
    }
  }

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

    await ref.read(secureStorageProvider).clearLoginSession();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[AuthController] Google sign out error: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AuthController] Firebase sign out error: $e');
    }

    state = const AsyncData(AuthStatus.unauthenticated);
  }

  Future<bool> checkPin(String pin) async {
    final storage = ref.read(secureStorageProvider);

    if (!await storage.hasConfiguredPinLock()) {
      return false;
    }

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

    if (currentPin != null) {
      final valid = await storage.verifyPin(currentPin);

      if (!valid) {
        return false;
      }
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

    final hasLock = await storage.hasConfiguredPinLock();

    state = AsyncData(
      hasLock ? AuthStatus.pinLocked : AuthStatus.authenticated,
    );
  }

  void onAppBackgrounded() {
    _backgroundedAt = DateTime.now();
  }

  Future<void> onAppResumed() async {
    final started = _backgroundedAt;

    _backgroundedAt = null;

    if (started == null) {
      return;
    }

    if (DateTime.now().difference(started) < _resumeLockAfter) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

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

      if (!supported || !canCheck) {
        return null;
      }

      if (biometrics.contains(BiometricType.face)) {
        return BiometricType.face;
      }

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
    if (await preferredBiometric() == null) {
      return false;
    }

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

    if (!await storage.hasConfiguredBiometricLock()) {
      return false;
    }

    final success = await promptBiometric(reason: 'Unlock Expense Tracker');

    if (success) {
      state = const AsyncData(AuthStatus.authenticated);
    }

    return success;
  }

  Future<bool> enableBiometricUnlock() async {
    final storage = ref.read(secureStorageProvider);

    if (!await storage.hasConfiguredPinLock()) {
      return false;
    }

    final available = await isBiometricAvailable();

    if (!available) {
      return false;
    }

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
