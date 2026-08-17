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

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
