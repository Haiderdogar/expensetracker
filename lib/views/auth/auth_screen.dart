import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import 'widgets/pin_pad_button.dart';

final _pinProvider = StateProvider.autoDispose<String>((ref) => '');
final _firstPinProvider = StateProvider.autoDispose<String?>((ref) => null);
final _errorProvider = StateProvider.autoDispose<String?>((ref) => null);
final _isConfirmStepProvider = StateProvider.autoDispose<bool>((ref) => false);

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.isSetup = false,
    this.verifyOnly = false,
    this.offerBiometricAfterSetup = false,
  });

  final bool isSetup;
  final bool verifyOnly;
  final bool offerBiometricAfterSetup;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _didPromptBiometric = false;
  int _failures = 0;
  DateTime? _cooldownUntil;

  bool get _isUnlock => !widget.isSetup && !widget.verifyOnly;

  String _title(bool isConfirm) {
    if (widget.verifyOnly) return AppStrings.enterPin;
    if (widget.isSetup) {
      return isConfirm ? AppStrings.confirmPin : AppStrings.createPin;
    }
    return AppStrings.enterPin;
  }

  @override
  void initState() {
    super.initState();
    if (_isUnlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _finishUnlocked() async {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _tryBiometric() async {
    if (_didPromptBiometric || !_isUnlock || !mounted) return;
    _didPromptBiometric = true;
    final enabled = await ref.read(biometricEnabledProvider.future);
    if (!enabled || !mounted) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .authenticateWithBiometric();
    if (success) await _finishUnlocked();
  }

  bool _inCooldown() {
    final until = _cooldownUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _cooldownUntil = null;
    _failures = 0;
    return false;
  }

  Future<void> _offerBiometric() async {
    final available = await ref
        .read(authControllerProvider.notifier)
        .isBiometricAvailable();
    if (!available || !mounted) return;

    final enable = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 48,
              color: AppColors.primaryEmerald,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.enableBiometricTitle,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.enableBiometricBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(AppStrings.enableBiometric),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(AppStrings.notNow),
            ),
          ],
        ),
      ),
    );

    if (enable != true || !mounted) return;
    final confirmed = await ref
        .read(authControllerProvider.notifier)
        .promptBiometric(reason: AppStrings.unlockWithBiometric);
    if (confirmed) {
      await ref.read(authControllerProvider.notifier).enableBiometricUnlock();
    }
  }

  Future<void> _handleComplete() async {
    if (_inCooldown()) {
      ref.read(_errorProvider.notifier).state = AppStrings.pinCooldown;
      return;
    }

    final currentPin = ref.read(_pinProvider);
    if (currentPin.length != 4) return;

    if (widget.verifyOnly) {
      final valid = await ref
          .read(authControllerProvider.notifier)
          .checkPin(currentPin);
      if (!valid) {
        await _onWrongPin();
        return;
      }
      await _finishUnlocked();
      return;
    }

    if (widget.isSetup) {
      if (!ref.read(_isConfirmStepProvider)) {
        ref.read(_firstPinProvider.notifier).state = currentPin;
        ref.read(_pinProvider.notifier).state = '';
        ref.read(_isConfirmStepProvider.notifier).state = true;
        return;
      }

      final firstPin = ref.read(_firstPinProvider);
      if (firstPin == null || currentPin != firstPin) {
        ref.read(_errorProvider.notifier).state = AppStrings.pinMismatch;
        ref.read(_pinProvider.notifier).state = '';
        ref.read(_firstPinProvider.notifier).state = null;
        ref.read(_isConfirmStepProvider.notifier).state = false;
        return;
      }

      await ref.read(authControllerProvider.notifier).setupPin(currentPin);
      if (widget.offerBiometricAfterSetup) {
        await _offerBiometric();
      }
      await _finishUnlocked();
      return;
    }

    final valid = await ref
        .read(authControllerProvider.notifier)
        .verifyPin(currentPin);
    if (!valid) {
      await _onWrongPin();
      return;
    }
    _failures = 0;
    await _finishUnlocked();
  }

  Future<void> _onWrongPin() async {
    HapticFeedback.mediumImpact();
    _failures += 1;
    ref.read(_pinProvider.notifier).state = '';
    if (_failures >= 5) {
      _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
      ref.read(_errorProvider.notifier).state = AppStrings.pinCooldown;
      if (mounted) setState(() {});
      return;
    }
    ref.read(_errorProvider.notifier).state = AppStrings.wrongPin;
  }

  void _onDigit(String digit) {
    if (_inCooldown()) {
      ref.read(_errorProvider.notifier).state = AppStrings.pinCooldown;
      if (mounted) setState(() {});
      return;
    }
    if (ref.read(_pinProvider).length >= 4) return;
    ref.read(_pinProvider.notifier).state = ref.read(_pinProvider) + digit;
    ref.read(_errorProvider.notifier).state = null;
    if (ref.read(_pinProvider).length == 4) _handleComplete();
  }

  void _onBackspace() {
    if (_inCooldown()) return;
    final current = ref.read(_pinProvider);
    if (current.isEmpty) return;
    ref.read(_pinProvider.notifier).state = current.substring(
      0,
      current.length - 1,
    );
    ref.read(_errorProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final pin = ref.watch(_pinProvider);
    final error = ref.watch(_errorProvider);
    final isConfirmStep = ref.watch(_isConfirmStepProvider);
    final biometricAsync = ref.watch(biometricEnabledProvider);
    final coolingDown = _inCooldown();

    return Scaffold(
      appBar: (widget.isSetup || widget.verifyOnly) &&
              Navigator.of(context).canPop()
          ? AppBar()
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.primaryEmerald,
              ),
              const SizedBox(height: 24),
              Text(
                _title(isConfirmStep),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (_isUnlock) ...[
                const SizedBox(height: 8),
                Text(
                  AppStrings.unlockSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppColors.primaryEmerald
                          : AppColors.gray200,
                    ),
                  );
                }),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(color: AppColors.expenseRed),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (final d in [
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                  ])
                    PinPadButton(
                      label: d,
                      onTap: coolingDown ? () {} : () => _onDigit(d),
                    ),
                  if (_isUnlock)
                    biometricAsync.when(
                      data: (enabled) => enabled
                          ? PinPadButton(
                              label: '',
                              icon: Icons.fingerprint,
                              onTap: () async {
                                final success = await ref
                                    .read(authControllerProvider.notifier)
                                    .authenticateWithBiometric();
                                if (success) await _finishUnlocked();
                              },
                            )
                          : const SizedBox(width: 72, height: 72),
                      loading: () => const SizedBox(width: 72, height: 72),
                      error: (_, _) => const SizedBox(width: 72, height: 72),
                    )
                  else
                    const SizedBox(width: 72, height: 72),
                  PinPadButton(
                    label: '0',
                    onTap: coolingDown ? () {} : () => _onDigit('0'),
                  ),
                  PinPadButton(
                    label: '',
                    icon: Icons.backspace_outlined,
                    onTap: _onBackspace,
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
