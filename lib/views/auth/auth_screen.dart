import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import 'widgets/pin_pad_button.dart';

final _pinProvider = StateProvider<String>((ref) => '');
final _firstPinProvider = StateProvider<String?>((ref) => null);
final _errorProvider = StateProvider<String?>((ref) => null);
final _isConfirmStepProvider = StateProvider<bool>((ref) => false);

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
      ref.read(_errorProvider.notifier).state = null;

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
        // Clear the controller so the user can re-enter for confirmation
        _pinController.clear();
        ref.read(_isConfirmStepProvider.notifier).state = true;
        return;
      }

      final firstPin = ref.read(_firstPinProvider);
      if (firstPin == null || currentPin != firstPin) {
        ref.read(_errorProvider.notifier).state = AppStrings.pinMismatch;
        _pinController.clear();
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
    ref.read(_errorProvider.notifier).state = null; // clear error
  }

  @override
  Widget build(BuildContext context) {
    final pin = ref.watch(_pinProvider);
    final error = ref.watch(_errorProvider);
    final isConfirmStep = ref.watch(_isConfirmStepProvider);
    final biometricAsync = ref.watch(biometricEnabledProvider);
    final coolingDown = _inCooldown();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
            final keypadHeight = (maxH * 0.45).clamp(
              keypadRowHeight * 4 + keypadSpacing * 3,
              520.0,
            );
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: maxH),
                child: IntrinsicHeight(
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
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryEmerald.withOpacity(0.12),
                              Theme.of(context).colorScheme.background,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
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
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.lock,
                                  size: 44,
                                  color: AppColors.primaryEmerald,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _title(isConfirmStep),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            if (_isUnlock) ...[
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

                      // Pin dots and error in an Expanded area so keypad stays visible
                      Expanded(
                        child: Padding(
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(4, (i) {
                                      final filled = i < pin.length;
                                      final focused = i == pin.length;
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        width: 64,
                                        height: 56,
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
                                                      .withOpacity(0.28)
                                                : AppColors.gray200,
                                            width: filled ? 2 : 1.2,
                                          ),
                                          boxShadow: filled
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors
                                                        .primaryEmerald
                                                        .withOpacity(0.12),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: filled
                                              ? Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration:
                                                      const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors
                                                            .primaryEmerald,
                                                      ),
                                                )
                                              : focused
                                              ? Container(
                                                  width: 2,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .primaryEmerald,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
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
                                      if (_pinController.text.length == 4)
                                        _handleComplete();
                                    },
                                    decoration: const InputDecoration.collapsed(
                                      hintText: '',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (error != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.expenseRed.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.expenseRed.withOpacity(
                                        0.12,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    error,
                                    style: const TextStyle(
                                      color: AppColors.expenseRed,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),

                      // Keypad fixed height area with bottom safe padding
                      Builder(
                        builder: (ctx) {
                          final bottomPad = MediaQuery.of(
                            ctx,
                          ).viewPadding.bottom;
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
                                            data: (enabled) => enabled
                                                ? PinPadButton(
                                                    label: '',
                                                    icon: Icons.fingerprint,
                                                    onTap: () async {
                                                      final success = await ref
                                                          .read(
                                                            authControllerProvider
                                                                .notifier,
                                                          )
                                                          .authenticateWithBiometric();
                                                      if (success)
                                                        await _finishUnlocked();
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
                                            error: (_, __) => const SizedBox(
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
              ),
            );
          },
        ),
      ),
    );
  }
}
