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
  pinLocked,
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

  bool _isGoogleSignInInProgress = false;

  String? _lastGoogleSignInError;

  String? get lastGoogleSignInError => _lastGoogleSignInError;

  String _activeUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('A signed-in Google user is required.');
    }
    return userId;
  }

  @override
  Future<AuthStatus> build() async {
    final storage = ref.read(secureStorageProvider);
    User? user;

    try {
      // Firebase normally restores this persisted credential itself. Reading
      // currentUser first avoids waiting on a stream event during bootstrap.
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('[AuthController] Unable to read Firebase session: $e');
    }

    // If Firebase has not reconstructed its session yet, use the local login
    // record only to attempt a non-interactive Google restore. The result is
    // always validated against the locally stored Firebase UID below.
    if (user == null && await storage.hasSavedLoginSession()) {
      user = await _restoreFirebaseSessionFromGoogle();
    }

    if (user == null) {
      return AuthStatus.unauthenticated;
    }

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

    // Capture the non-null UID before using it from callbacks. Dart does not
    // promote a nullable variable inside a closure because it could change.
    final userId = user.uid;

    await storage.migrateLegacySecurityForUser(userId);

    await ref.read(databaseHelperProvider).ensureUserInitialized(userId);

    final syncRepo = ref.read(syncRepositoryProvider);

    syncRepo.initConnectivityListener(() => userId);

    unawaited(_reconcileAndRefresh(userId));

    if (await storage.hasConfiguredPinLock(userId)) {
      return AuthStatus.pinLocked;
    }

    // A valid local login session restores the Google login on app launch.
    // The post-login flow will then decide whether wallet setup is still
    // required for this user.
    return AuthStatus.authenticated;
  }

  Future<User?> _restoreFirebaseSessionFromGoogle() async {
    try {
      await GoogleSignInService.ensureInitialized();
      final restoreAttempt = GoogleSignIn.instance
          .attemptLightweightAuthentication();
      final googleUser = restoreAttempt == null ? null : await restoreAttempt;
      final idToken = googleUser?.authentication.idToken;

      if (idToken == null || idToken.isEmpty) return null;

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));
      return result.user;
    } catch (e) {
      // A silent restore is best-effort. The user can still use the normal
      // Google sign-in button if the Google session no longer exists.
      debugPrint('[AuthController] Silent session restore failed: $e');
      return null;
    }
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
       * Persist the successful login before any optional profile or sync work.
       * This is the credential record consulted during the next app launch,
       * including when the user closes the app while wallet setup is open.
       */
      final storage = ref.read(secureStorageProvider);
      final previousUserId = await storage.readSavedLoginUserId();
      if (previousUserId != null && previousUserId != user.uid) {
        // Legacy lock keys had no account scope. They cannot safely cross an
        // account switch, so discard them rather than exposing account A's
        // PIN/biometric preference to account B.
        await storage.clearLegacySecurity();
      } else if (previousUserId == user.uid) {
        await storage.migrateLegacySecurityForUser(user.uid);
      }
      await storage.saveLoginSession(userId: user.uid, email: user.email);

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

      // The app can have evaluated user-scoped providers while the login
      // screen was visible. Refresh the identity providers before routing to
      // the post-login flow so wallet setup is checked for this UID.
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserIdProvider);

      /*
       * Initialize sync after successful authentication.
       */
      final syncRepo = ref.read(syncRepositoryProvider);

      syncRepo.initConnectivityListener(() => user.uid);

      unawaited(_reconcileAndRefresh(user.uid, preferLocal: false));

      /*
       * Mark this process as successfully authenticated.
       */
      /*
       * Startup listens to this authentication state and selects the next
       * account-specific flow.
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

  Future<void> signOut() async {
    _backgroundedAt = null;
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
    final userId = _activeUserId();

    if (!await storage.hasConfiguredPinLock(userId)) {
      return false;
    }

    return storage.verifyPin(pin, userId);
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
    final userId = _activeUserId();

    await storage.savePinHash(pin, userId);
    await storage.setPinEnabled(true, userId);
    await storage.setLockPromptCompleted(true, userId);
    await storage.setSecuritySetupPending(userId, false);

    ref.invalidate(pinEnabledProvider);
    ref.invalidate(biometricEnabledProvider);

    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<void> skipLockSetup() async {
    final storage = ref.read(secureStorageProvider);
    final userId = _activeUserId();

    await storage.setLockPromptCompleted(true, userId);
    await storage.setSecuritySetupPending(userId, false);

    ref.invalidate(pinEnabledProvider);

    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<bool> disablePin({String? currentPin}) async {
    final storage = ref.read(secureStorageProvider);
    final userId = _activeUserId();

    if (currentPin != null) {
      final valid = await storage.verifyPin(currentPin, userId);

      if (!valid) {
        return false;
      }
    }

    await storage.deletePin(userId);
    await storage.setBiometricEnabled(false, userId);

    ref.invalidate(pinEnabledProvider);
    ref.invalidate(biometricEnabledProvider);

    state = const AsyncData(AuthStatus.authenticated);

    return true;
  }

  Future<void> lock() async {
    final storage = ref.read(secureStorageProvider);
    final userId = _activeUserId();

    final hasLock = await storage.hasConfiguredPinLock(userId);

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

    if (await storage.hasConfiguredPinLock(user.uid)) {
      state = const AsyncData(AuthStatus.pinLocked);
    }
  }

  Future<void> logout() async {
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
    final userId = _activeUserId();

    if (!await storage.hasConfiguredBiometricLock(userId)) {
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
    final userId = _activeUserId();

    if (!await storage.hasConfiguredPinLock(userId)) {
      return false;
    }

    final available = await isBiometricAvailable();

    if (!available) {
      return false;
    }

    await storage.setBiometricEnabled(true, userId);

    ref.invalidate(biometricEnabledProvider);

    return true;
  }
}

@riverpod
Future<bool> pinEnabled(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'default_user') return false;
  return ref.read(secureStorageProvider).hasConfiguredPinLock(userId);
}

@riverpod
Future<bool> biometricEnabled(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'default_user') return false;
  return ref.read(secureStorageProvider).hasConfiguredBiometricLock(userId);
}

@riverpod
Future<String> currencySymbol(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);

  return ref.read(databaseHelperProvider).getCurrencySymbol(userId);
}
