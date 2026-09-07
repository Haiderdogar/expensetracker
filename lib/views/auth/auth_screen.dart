import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import 'widgets/pin_pad_button.dart';

final _pinProvider = StateProvider.autoDispose<String>((ref) => '');
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
  bool _biometricMode = true;
  BiometricType? _biometricType;
  bool _isSubmitting = false;
  int _failures = 0;
  DateTime? _cooldownUntil;
  String? _firstPin;

  // Controller & focus node to use the platform numeric keyboard (phone keyboard)
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool get _isUnlock => !widget.isSetup && !widget.verifyOnly;

  String _title(bool isConfirm) {
    if (widget.verifyOnly) return AppStrings.enterPin;
    if (widget.isSetup) {
      return isConfirm ? AppStrings.confirmPin : AppStrings.createPin;
    }
    return AppStrings.enterPin;
  }

  IconData get _biometricIcon =>
      _biometricType == BiometricType.face ? Icons.face : Icons.fingerprint;

  String get _biometricTitle => _biometricType == BiometricType.face
      ? AppStrings.unlockWithFace
      : AppStrings.unlockWithFingerprint;

  @override
  void initState() {
    super.initState();
    if (_isUnlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }

    // Listen to the hidden TextField controller to update provider state and
    // complete entry when 4 digits are typed. Use phone keyboard and digits-only filter.
    _pinController.addListener(() {
      final text = _pinController.text;
      final filtered = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (filtered != text) {
        // sanitize input and keep cursor at end
        _pinController.text = filtered;
        _pinController.selection = TextSelection.fromPosition(
          TextPosition(offset: _pinController.text.length),
        );
        return;
      }

      // sync to provider
      ref.read(_pinProvider.notifier).state = filtered;

      if (filtered.length == 4) {
        // allow UI to update before handling completion
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleComplete());
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
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
    if (enabled) await _promptBiometric();
    if (mounted && _biometricMode) setState(() => _biometricMode = false);
  }

  Future<void> _promptBiometric() async {
    if (!_isUnlock || !mounted) return;
    _biometricType = await ref
        .read(authControllerProvider.notifier)
        .preferredBiometric();
    if (_biometricType == null || !mounted) return;

    setState(() => _biometricMode = true);
    final success = await ref
        .read(authControllerProvider.notifier)
        .authenticateWithBiometric();
    if (success) {
      await _finishUnlocked();
    } else if (mounted) {
      setState(() => _biometricMode = false);
    }
  }

  void _usePin() {
    if (!_isUnlock) return;
    setState(() => _biometricMode = false);
    FocusScope.of(context).requestFocus(_pinFocusNode);
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
    if (_isSubmitting) return;
    if (_inCooldown()) {
      _showPinMessage(AppStrings.pinCooldown);
      return;
    }

    final currentPin = ref.read(_pinProvider);
    if (currentPin.length != 4) return;
    _isSubmitting = true;

    try {
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
          _firstPin = currentPin;
          _clearPinEntry();
          ref.read(_isConfirmStepProvider.notifier).state = true;
          return;
        }

        final firstPin = _firstPin;
        if (firstPin == null || currentPin != firstPin) {
          _resetPinSetup();
          _showPinMessage(AppStrings.pinMismatch);
          return;
        }

        await ref.read(authControllerProvider.notifier).setupPin(currentPin);
        _resetPinSetup();
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
    } finally {
      _isSubmitting = false;
    }
  }

  Future<void> _onWrongPin() async {
    HapticFeedback.mediumImpact();
    _failures += 1;
    _clearPinEntry();
    if (_failures >= 5) {
      _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
      if (mounted) setState(() {});
      _showPinMessage(AppStrings.pinCooldown);
      return;
    }
    _showPinMessage(AppStrings.wrongPin);
  }

  void _showPinMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _clearPinEntry() {
    _pinController.clear();
    ref.read(_pinProvider.notifier).state = '';
  }

  void _resetPinSetup() {
    _firstPin = null;
    _clearPinEntry();
    ref.read(_isConfirmStepProvider.notifier).state = false;
  }

  void _onDigit(String digit) {
    if (_inCooldown()) {
      _showPinMessage(AppStrings.pinCooldown);
      if (mounted) setState(() {});
      return;
    }
    if (_pinController.text.length >= 4) return;
    // update controller which will sync to provider via listener
    _pinController.text = _pinController.text + digit;
    _pinController.selection = TextSelection.fromPosition(
      TextPosition(offset: _pinController.text.length),
    );
  }

  void _onBackspace() {
    if (_inCooldown()) return;
    final current = _pinController.text;
    if (current.isEmpty) return;
    _pinController.text = current.substring(0, current.length - 1);
    _pinController.selection = TextSelection.fromPosition(
      TextPosition(offset: _pinController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = ref.watch(_pinProvider);
    final isConfirmStep = ref.watch(_isConfirmStepProvider);
    final biometricAsync = ref.watch(biometricEnabledProvider);
    final coolingDown = _inCooldown();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar:
          (widget.isSetup || widget.verifyOnly) &&
              Navigator.of(context).canPop()
          ? AppBar(backgroundColor: Colors.transparent, elevation: 0)
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight;
            const keypadRowHeight = 72.0;
            const keypadSpacing = 12.0;
            final keypadHeight = (maxH * 0.4).clamp(
              keypadRowHeight * 4 + keypadSpacing * 3,
              440.0,
            );
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: maxH),
                child: Column(
                  children: [
                    // Header with gradient and lock icon
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _isUnlock && _biometricMode
                                    ? _biometricIcon
                                    : Icons.lock,
                                size: 44,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isUnlock && _biometricMode
                                ? _biometricTitle
                                : _title(isConfirmStep),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          if (_isUnlock && _biometricMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.unlockWithBiometric,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _usePin,
                              child: const Text(AppStrings.usePin),
                            ),
                          ] else if (_isUnlock) ...[
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.unlockSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Keep this section non-flexible because it is inside a
                    // scroll view and must adapt to short device displays.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Tappable area to open system numeric keyboard
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => FocusScope.of(
                              context,
                            ).requestFocus(_pinFocusNode),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Row(
                                key: ValueKey(pin),
                                children: List.generate(4, (i) {
                                  final filled = i < pin.length;
                                  final focused = i == pin.length;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: i == 0 ? 0 : 4,
                                        right: i == 3 ? 0 : 4,
                                      ),
                                      child: SizedBox(
                                        height: 56,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: filled
                                                  ? AppColors.primaryEmerald
                                                  : focused
                                                  ? AppColors.primaryEmerald
                                                        .withValues(alpha: 0.28)
                                                  : AppColors.gray200,
                                              width: filled ? 2 : 1.2,
                                            ),
                                            boxShadow: filled
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .primaryEmerald
                                                          .withValues(alpha: 0.12),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        6,
                                                      ),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: filled
                                                ? FractionallySizedBox(
                                                    widthFactor: 0.22,
                                                    child: AspectRatio(
                                                      aspectRatio: 1,
                                                      child: DecoratedBox(
                                                        decoration:
                                                            const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: AppColors
                                                                  .primaryEmerald,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                : focused
                                                ? FractionallySizedBox(
                                                    heightFactor: 0.43,
                                                    child: Container(
                                                      width: 2,
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .primaryEmerald,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              2,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                          // invisible TextField to receive numeric input from system keyboard
                          Opacity(
                            opacity: 0,
                            child: SizedBox(
                              height: 1,
                              width: 1,
                              child: TextField(
                                controller: _pinController,
                                focusNode: _pinFocusNode,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onSubmitted: (_) {
                                  if (_pinController.text.length == 4) {
                                    _handleComplete();
                                  }
                                },
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Keypad fixed height area with bottom safe padding
                    Builder(
                      builder: (ctx) {
                        final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            0,
                            24,
                            bottomPad + 36,
                          ),
                          child: SizedBox(
                            height: keypadHeight,
                            child: GridView.custom(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: keypadSpacing,
                                    crossAxisSpacing: keypadSpacing,
                                    mainAxisExtent: keypadRowHeight,
                                  ),
                              childrenDelegate: SliverChildListDelegate.fixed([
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
                                  Center(
                                    child: PinPadButton(
                                      label: d,
                                      onTap: coolingDown
                                          ? () {}
                                          : () => _onDigit(d),
                                    ),
                                  ),
                                Center(
                                  child: _isUnlock
                                      ? biometricAsync.when(
                                          data: (enabled) =>
                                              enabled && _biometricType != null
                                              ? PinPadButton(
                                                  label: '',
                                                  icon: _biometricIcon,
                                                  onTap: () async {
                                                    await _promptBiometric();
                                                  },
                                                )
                                              : const SizedBox(
                                                  width: 72,
                                                  height: 72,
                                                ),
                                          loading: () => const SizedBox(
                                            width: 72,
                                            height: 72,
                                          ),
                                          error: (_, _) => const SizedBox(
                                            width: 72,
                                            height: 72,
                                          ),
                                        )
                                      : const SizedBox(width: 72, height: 72),
                                ),
                                Center(
                                  child: PinPadButton(
                                    label: '0',
                                    onTap: coolingDown
                                        ? () {}
                                        : () => _onDigit('0'),
                                  ),
                                ),
                                Center(
                                  child: PinPadButton(
                                    label: '',
                                    icon: Icons.backspace_outlined,
                                    onTap: _onBackspace,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
