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
  static const String installationIdKey = 'installation_id';
  static const String introOnboardingSeenKey = 'intro_onboarding_seen';
  static const String welcomeSetupCompletedKey = 'welcome_setup_completed';
  static const String loginUserIdKey = 'login_user_id';
  static const String loginEmailKey = 'login_email';
  static const String loginAtKey = 'login_at';

  static const Duration loginValidity = Duration(days: 30);

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

  Future<String?> readPinHash() async {
    try {
      return await _storage.read(key: pinKey);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> savePinHash(String pin) async {
    try {
      final hash = _hashPin(pin);
      await _storage.write(key: pinKey, value: hash);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final stored = await readPinHash();
      if (stored == null) return false;
      return stored == _hashPin(pin);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> hasPin() async {
    final hash = await readPinHash();
    return hash != null && hash.isNotEmpty;
  }

  /// A PIN lock is usable only when both its setting and credential exist.
  Future<bool> hasConfiguredPinLock() async {
    return await isPinEnabled() && await hasPin();
  }

  /// Biometric unlock always falls back to the configured PIN credential.
  Future<bool> hasConfiguredBiometricLock() async {
    return await isBiometricEnabled() && await hasConfiguredPinLock();
  }

  Future<void> deletePin() async {
    try {
      await _storage.delete(key: pinKey);
      await _storage.delete(key: pinEnabledKey);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> isPinEnabled() async {
    try {
      final value = await _storage.read(key: pinEnabledKey);
      return value == 'true';
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setPinEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: pinEnabledKey,
        value: enabled ? 'true' : 'false',
      );
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: biometricKey);
      return value == 'true';
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: biometricKey,
        value: enabled ? 'true' : 'false',
      );
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<bool> isLockPromptCompleted() async {
    try {
      final value = await _storage.read(key: lockPromptKey);
      if (value == 'true') return true;
      return await isPinEnabled() && await hasPin();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setLockPromptCompleted(bool completed) async {
    try {
      await _storage.write(
        key: lockPromptKey,
        value: completed ? 'true' : 'false',
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
