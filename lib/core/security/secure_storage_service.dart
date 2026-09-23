import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/error_handler.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String pinKey = 'app_secure_pin';
  static const String pinEnabledKey = 'pin_enabled';
  static const String biometricKey = 'biometric_enabled';
  static const String lockPromptKey = 'lock_prompt_completed';
  static const String securitySetupPendingKey = 'security_setup_pending';
  static const String installationIdKey = 'installation_id';
  static const String introOnboardingSeenKey = 'intro_onboarding_seen';
  static const String welcomeSetupCompletedKey = 'welcome_setup_completed';
  static const String loginUserIdKey = 'login_user_id';
  static const String loginEmailKey = 'login_email';
  static const String loginAtKey = 'login_at';

  static const Duration loginValidity = Duration(days: 60);

  String _accountKey(String key, String? userId) =>
      userId == null || userId.isEmpty ? key : '${key}_$userId';

  Future<void> saveLoginSession({
    required String userId,
    required String? email,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: loginUserIdKey, value: userId),
        _storage.write(key: loginEmailKey, value: email?.trim() ?? ''),
        _storage.write(
          key: loginAtKey,
          value: DateTime.now().toUtc().toIso8601String(),
        ),
      ]);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> hasValidLoginSession(String userId) async {
    try {
      final storedUserId = await _storage.read(key: loginUserIdKey);
      final rawLoginAt = await _storage.read(key: loginAtKey);
      if (storedUserId != userId || rawLoginAt == null) return false;

      final loginAt = DateTime.tryParse(rawLoginAt);
      if (loginAt == null ||
          DateTime.now().toUtc().difference(loginAt) >= loginValidity) {
        await clearLoginSession();
        return false;
      }
      return true;
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  /// Returns whether this device has an unexpired local login record.
  ///
  /// This is deliberately not sufficient to authorize the app by itself. It
  /// is only used to decide whether a silent Google/Firebase restore should be
  /// attempted; [hasValidLoginSession] still verifies the Firebase user ID.
  Future<bool> hasSavedLoginSession() async {
    try {
      final storedUserId = await _storage.read(key: loginUserIdKey);
      final rawLoginAt = await _storage.read(key: loginAtKey);
      if (storedUserId == null || storedUserId.isEmpty || rawLoginAt == null) {
        return false;
      }

      final loginAt = DateTime.tryParse(rawLoginAt);
      if (loginAt == null ||
          DateTime.now().toUtc().difference(loginAt) >= loginValidity) {
        await clearLoginSession();
        return false;
      }
      return true;
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> clearLoginSession() async {
    try {
      await _storage.delete(key: loginUserIdKey);
      await _storage.delete(key: loginEmailKey);
      await _storage.delete(key: loginAtKey);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> hasSeenIntroOnboarding() async {
    try {
      return await _storage.read(key: introOnboardingSeenKey) == 'true';
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setIntroOnboardingSeen() async {
    try {
      await _storage.write(key: introOnboardingSeenKey, value: 'true');
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> hasCompletedWelcomeSetup() async {
    try {
      return await _storage.read(key: welcomeSetupCompletedKey) == 'true';
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setWelcomeSetupCompleted() async {
    try {
      await _storage.write(key: welcomeSetupCompletedKey, value: 'true');
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<String?> readInstallationId() async {
    try {
      return await _storage.read(key: installationIdKey);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> saveInstallationId(String installationId) async {
    try {
      await _storage.write(key: installationIdKey, value: installationId);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> clearAuthentication() async {
    try {
      await _storage.delete(key: pinKey);
      await _storage.delete(key: pinEnabledKey);
      await _storage.delete(key: biometricKey);
      await _storage.delete(key: lockPromptKey);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<String?> readPinHash([String? userId]) async {
    try {
      return await _storage.read(key: _accountKey(pinKey, userId));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> savePinHash(String pin, [String? userId]) async {
    try {
      final hash = _hashPin(pin);
      await _storage.write(key: _accountKey(pinKey, userId), value: hash);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> verifyPin(String pin, [String? userId]) async {
    try {
      final stored = await readPinHash(userId);
      if (stored == null) return false;
      return stored == _hashPin(pin);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> hasPin([String? userId]) async {
    final hash = await readPinHash(userId);
    return hash != null && hash.isNotEmpty;
  }

  /// A PIN lock is usable only when both its setting and credential exist.
  Future<bool> hasConfiguredPinLock([String? userId]) async {
    return await isPinEnabled(userId) && await hasPin(userId);
  }

  /// Biometric unlock always falls back to the configured PIN credential.
  Future<bool> hasConfiguredBiometricLock([String? userId]) async {
    return await isBiometricEnabled(userId) &&
        await hasConfiguredPinLock(userId);
  }

  Future<void> deletePin([String? userId]) async {
    try {
      await _storage.delete(key: _accountKey(pinKey, userId));
      await _storage.delete(key: _accountKey(pinEnabledKey, userId));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> resetPinSecurity([String? userId]) async {
    try {
      await Future.wait([
        _storage.delete(key: _accountKey(pinKey, userId)),
        _storage.delete(key: _accountKey(pinEnabledKey, userId)),
        _storage.delete(key: _accountKey(biometricKey, userId)),
      ]);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> isPinEnabled([String? userId]) async {
    try {
      final value = await _storage.read(
        key: _accountKey(pinEnabledKey, userId),
      );
      return value == 'true';
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setPinEnabled(bool enabled, [String? userId]) async {
    try {
      await _storage.write(
        key: _accountKey(pinEnabledKey, userId),
        value: enabled ? 'true' : 'false',
      );
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> isBiometricEnabled([String? userId]) async {
    try {
      final value = await _storage.read(key: _accountKey(biometricKey, userId));
      return value == 'true';
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setBiometricEnabled(bool enabled, [String? userId]) async {
    try {
      await _storage.write(
        key: _accountKey(biometricKey, userId),
        value: enabled ? 'true' : 'false',
      );
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> isLockPromptCompleted([String? userId]) async {
    try {
      final value = await _storage.read(
        key: _accountKey(lockPromptKey, userId),
      );
      if (value == 'true') return true;
      return await isPinEnabled(userId) && await hasPin(userId);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setLockPromptCompleted(bool completed, [String? userId]) async {
    try {
      await _storage.write(
        key: _accountKey(lockPromptKey, userId),
        value: completed ? 'true' : 'false',
      );
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<String?> readSavedLoginUserId() => _storage.read(key: loginUserIdKey);

  Future<void> clearLegacySecurity() async {
    try {
      await Future.wait([
        _storage.delete(key: pinKey),
        _storage.delete(key: pinEnabledKey),
        _storage.delete(key: biometricKey),
        _storage.delete(key: lockPromptKey),
      ]);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  /// One-time migration for installs created before lock data was scoped to a
  /// Firebase UID. It is safe because callers invoke it only after verifying
  /// that the restored login session belongs to [userId].
  Future<void> migrateLegacySecurityForUser(String userId) async {
    try {
      final scopedPin = await _storage.read(key: _accountKey(pinKey, userId));
      if (scopedPin != null) return;

      final legacyPin = await _storage.read(key: pinKey);
      if (legacyPin == null || legacyPin.isEmpty) return;

      final legacyPinEnabled = await _storage.read(key: pinEnabledKey);
      final legacyBiometric = await _storage.read(key: biometricKey);
      final legacyPrompt = await _storage.read(key: lockPromptKey);
      await Future.wait([
        _storage.write(key: _accountKey(pinKey, userId), value: legacyPin),
        _storage.write(
          key: _accountKey(pinEnabledKey, userId),
          value: legacyPinEnabled ?? 'false',
        ),
        _storage.write(
          key: _accountKey(biometricKey, userId),
          value: legacyBiometric ?? 'false',
        ),
        _storage.write(
          key: _accountKey(lockPromptKey, userId),
          value: legacyPrompt ?? 'true',
        ),
        _storage.delete(key: pinKey),
        _storage.delete(key: pinEnabledKey),
        _storage.delete(key: biometricKey),
        _storage.delete(key: lockPromptKey),
      ]);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  /// This state exists only between first wallet creation and the user's
  /// explicit PIN/biometric choice. It is scoped by Firebase UID so another
  /// Google account cannot inherit it.
  Future<bool> isSecuritySetupPending(String userId) async {
    try {
      return await _storage.read(key: '${securitySetupPendingKey}_$userId') ==
          'true';
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setSecuritySetupPending(String userId, bool pending) async {
    try {
      await _storage.write(
        key: '${securitySetupPendingKey}_$userId',
        value: pending ? 'true' : 'false',
      );
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
