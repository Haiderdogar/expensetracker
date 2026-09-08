import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import 'auth_ui_providers.dart';

class AuthFlow {
  const AuthFlow._();

  static bool isCoolingDown(AuthUiState state) {
    final until = state.cooldownUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  static void updatePin(WidgetRef ref, AuthScreenConfig config, String value) {
    final rawPin = value.replaceAll(RegExp(r'[^0-9]'), '');
    final pin = rawPin.length > 4 ? rawPin.substring(0, 4) : rawPin;
    ref.read(authUiStateProvider(config).notifier).state = ref.read(authUiStateProvider(config)).copyWith(pin: pin);
  }

  static void addDigit(BuildContext context, WidgetRef ref, AuthScreenConfig config, String digit) {
    final state = _refreshCooldown(ref, config);
    if (isCoolingDown(state)) {
      showMessage(context, AppStrings.pinCooldown);
      return;
    }
    if (state.pin.length >= 4) return;
    final controller = ref.read(authPinControllerProvider(config));
    controller.text = state.pin + digit;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    updatePin(ref, config, controller.text);
    if (controller.text.length == 4) complete(context, ref, config);
  }

  static void backspace(WidgetRef ref, AuthScreenConfig config) {
    final state = ref.read(authUiStateProvider(config));
    if (isCoolingDown(state) || state.pin.isEmpty) return;
    final pin = state.pin.substring(0, state.pin.length - 1);
    final controller = ref.read(authPinControllerProvider(config));
    controller.text = pin;
    controller.selection = TextSelection.collapsed(offset: pin.length);
    updatePin(ref, config, pin);
  }

  static void clearPin(WidgetRef ref, AuthScreenConfig config) {
    ref.read(authPinControllerProvider(config)).clear();
    ref.read(authUiStateProvider(config).notifier).state = ref.read(authUiStateProvider(config)).copyWith(pin: '');
  }

  static Future<void> complete(BuildContext context, WidgetRef ref, AuthScreenConfig config) async {
    var state = _refreshCooldown(ref, config);
    if (state.isSubmitting || state.pin.length != 4) return;
    if (isCoolingDown(state)) {
      showMessage(context, AppStrings.pinCooldown);
      return;
    }
    ref.read(authUiStateProvider(config).notifier).state = state.copyWith(isSubmitting: true);
    try {
      if (config.verifyOnly) {
        if (await ref.read(authControllerProvider.notifier).checkPin(state.pin)) {
          finish(context);
        } else {
          await wrongPin(context, ref, config);
        }
        return;
      }
      if (config.isSetup) {
        if (!state.isConfirmStep) {
          ref.read(authUiStateProvider(config).notifier).state = state.copyWith(firstPin: state.pin, isConfirmStep: true, pin: '');
          ref.read(authPinControllerProvider(config)).clear();
          return;
        }
        if (state.firstPin == null || state.pin != state.firstPin) {
          ref.read(authUiStateProvider(config).notifier).state = state.copyWith(pin: '', clearFirstPin: true, isConfirmStep: false);
          ref.read(authPinControllerProvider(config)).clear();
          showMessage(context, AppStrings.pinMismatch);
          return;
        }
        await ref.read(authControllerProvider.notifier).setupPin(state.pin);
        if (config.offerBiometricAfterSetup) await offerBiometric(context, ref, config);
        finish(context);
        return;
      }
      if (await ref.read(authControllerProvider.notifier).verifyPin(state.pin)) {
        finish(context);
      } else {
        await wrongPin(context, ref, config);
      }
    } finally {
      if (context.mounted) {
        state = ref.read(authUiStateProvider(config));
        ref.read(authUiStateProvider(config).notifier).state = state.copyWith(isSubmitting: false);
      }
    }
  }

  static Future<void> wrongPin(BuildContext context, WidgetRef ref, AuthScreenConfig config) async {
    HapticFeedback.mediumImpact();
    final state = ref.read(authUiStateProvider(config));
    final failures = state.failures + 1;
    final coolingDown = failures >= 5;
    ref.read(authUiStateProvider(config).notifier).state = state.copyWith(
      pin: '',
      failures: coolingDown ? failures : failures,
      cooldownUntil: coolingDown ? DateTime.now().add(const Duration(seconds: 30)) : null,
    );
    ref.read(authPinControllerProvider(config)).clear();
    showMessage(context, coolingDown ? AppStrings.pinCooldown : AppStrings.wrongPin);
  }

  static Future<void> startBiometric(BuildContext context, WidgetRef ref, AuthScreenConfig config) async {
    if (!config.isUnlock) return;
    final state = ref.read(authUiStateProvider(config));
    if (state.didPromptBiometric) return;
    ref.read(authUiStateProvider(config).notifier).state = state.copyWith(didPromptBiometric: true);
    if (await ref.read(biometricEnabledProvider.future)) await promptBiometric(context, ref, config);
  }

  static Future<void> promptBiometric(BuildContext context, WidgetRef ref, AuthScreenConfig config) async {
    if (!config.isUnlock || !context.mounted) return;
    final type = await ref.read(authControllerProvider.notifier).preferredBiometric();
    if (type == null || !context.mounted) return;
    var state = ref.read(authUiStateProvider(config));
    ref.read(authUiStateProvider(config).notifier).state = state.copyWith(isBiometricMode: true, biometricType: type);
    final success = await ref.read(authControllerProvider.notifier).authenticateWithBiometric();
    if (success) {
      finish(context);
    } else if (context.mounted) {
      state = ref.read(authUiStateProvider(config));
      ref.read(authUiStateProvider(config).notifier).state = state.copyWith(isBiometricMode: false);
    }
  }

  static void usePin(BuildContext context, WidgetRef ref, AuthScreenConfig config) {
    final state = ref.read(authUiStateProvider(config));
    ref.read(authUiStateProvider(config).notifier).state = state.copyWith(isBiometricMode: false);
    FocusScope.of(context).requestFocus(ref.read(authPinFocusNodeProvider(config)));
  }

  static Future<void> offerBiometric(BuildContext context, WidgetRef ref, AuthScreenConfig config) async {
    if (!await ref.read(authControllerProvider.notifier).isBiometricAvailable() || !context.mounted) return;
    final enable = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.fingerprint, size: 48, color: AppColors.primaryEmerald),
          const SizedBox(height: 16),
          Text(AppStrings.enableBiometricTitle, style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(AppStrings.enableBiometricBody, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => Navigator.of(sheetContext).pop(true), child: const Text(AppStrings.enableBiometric)),
          TextButton(onPressed: () => Navigator.of(sheetContext).pop(false), child: const Text(AppStrings.notNow)),
        ]),
      ),
    );
    if (enable == true && context.mounted && await ref.read(authControllerProvider.notifier).promptBiometric(reason: AppStrings.unlockWithBiometric)) {
      await ref.read(authControllerProvider.notifier).enableBiometricUnlock();
    }
  }

  static void finish(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop(true);
  }

  static void showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  static AuthUiState _refreshCooldown(WidgetRef ref, AuthScreenConfig config) {
    final state = ref.read(authUiStateProvider(config));
    final until = state.cooldownUntil;
    if (until == null || DateTime.now().isBefore(until)) return state;
    final refreshed = state.copyWith(failures: 0, clearCooldown: true);
    ref.read(authUiStateProvider(config).notifier).state = refreshed;
    return refreshed;
  }
}
