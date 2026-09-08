import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';

class AuthScreenConfig {
  const AuthScreenConfig({
    required this.isSetup,
    required this.verifyOnly,
    required this.offerBiometricAfterSetup,
  });

  final bool isSetup;
  final bool verifyOnly;
  final bool offerBiometricAfterSetup;

  bool get isUnlock => !isSetup && !verifyOnly;

  @override
  bool operator ==(Object other) {
    return other is AuthScreenConfig &&
        other.isSetup == isSetup &&
        other.verifyOnly == verifyOnly &&
        other.offerBiometricAfterSetup == offerBiometricAfterSetup;
  }

  @override
  int get hashCode => Object.hash(isSetup, verifyOnly, offerBiometricAfterSetup);
}

class AuthUiState {
  const AuthUiState({
    this.pin = '',
    this.firstPin,
    this.isConfirmStep = false,
    this.isSubmitting = false,
    this.failures = 0,
    this.cooldownUntil,
    this.isBiometricMode = false,
    this.didPromptBiometric = false,
    this.biometricType,
  });

  final String pin;
  final String? firstPin;
  final bool isConfirmStep;
  final bool isSubmitting;
  final int failures;
  final DateTime? cooldownUntil;
  final bool isBiometricMode;
  final bool didPromptBiometric;
  final BiometricType? biometricType;

  AuthUiState copyWith({
    String? pin,
    String? firstPin,
    bool clearFirstPin = false,
    bool? isConfirmStep,
    bool? isSubmitting,
    int? failures,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
    bool? isBiometricMode,
    bool? didPromptBiometric,
    BiometricType? biometricType,
    bool clearBiometricType = false,
  }) {
    return AuthUiState(
      pin: pin ?? this.pin,
      firstPin: clearFirstPin ? null : firstPin ?? this.firstPin,
      isConfirmStep: isConfirmStep ?? this.isConfirmStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failures: failures ?? this.failures,
      cooldownUntil: clearCooldown ? null : cooldownUntil ?? this.cooldownUntil,
      isBiometricMode: isBiometricMode ?? this.isBiometricMode,
      didPromptBiometric: didPromptBiometric ?? this.didPromptBiometric,
      biometricType: clearBiometricType ? null : biometricType ?? this.biometricType,
    );
  }
}

final authUiStateProvider = StateProvider.autoDispose.family<AuthUiState, AuthScreenConfig>(
  (ref, config) => const AuthUiState(),
);

final authPinControllerProvider = Provider.autoDispose.family<TextEditingController, AuthScreenConfig>((ref, config) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final authPinFocusNodeProvider = Provider.autoDispose.family<FocusNode, AuthScreenConfig>((ref, config) {
  final focusNode = FocusNode();
  ref.onDispose(focusNode.dispose);
  return focusNode;
});
