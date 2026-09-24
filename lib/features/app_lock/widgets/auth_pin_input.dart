import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../google_sign_in/providers/auth_provider.dart';
import '../providers/auth_flow.dart';
import '../providers/auth_ui_providers.dart';

class AuthPinInput extends ConsumerWidget {
  const AuthPinInput({super.key, required this.config});

  final AuthScreenConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authUiStateProvider(config));
    final colors = Theme.of(context).colorScheme;
    final biometricEnabled = ref.watch(biometricEnabledProvider).value == true;
    final biometricIcon = state.biometricType?.name == 'face'
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(240.0, 390.0).toDouble();
        final buttonSize = (width * 0.24).clamp(66.0, 88.0).toDouble();
        final gap = (width * 0.035).clamp(8.0, 12.0).toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PinIndicators(
              pin: state.pin,
              isSubmitting: state.isSubmitting,
              colors: colors,
            ),
            const SizedBox(height: 12),
            if (!state.isBiometricMode)
              _NumberPad(
                config: config,
                buttonSize: buttonSize,
                gap: gap,
                biometricEnabled: biometricEnabled,
                biometricIcon: biometricIcon,
              ),
            if (state.isRecoveringPin) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 8),
              Text(
                AppStrings.pinRecoveryInProgress,
                style: TextStyle(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _NumberPad extends ConsumerWidget {
  const _NumberPad({
    required this.config,
    required this.buttonSize,
    required this.gap,
    required this.biometricEnabled,
    required this.biometricIcon,
  });

  final AuthScreenConfig config;
  final double buttonSize;
  final double gap;
  final bool biometricEnabled;
  final IconData biometricIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authUiStateProvider(config));
    final disabled = state.isRecoveringPin || state.isSubmitting;
    final digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var column = 0; column < 3; column++)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gap / 2),
                    child: _PadButton(
                      size: buttonSize,
                      label: digits[row * 3 + column],
                      enabled: !disabled,
                      onTap: () => AuthFlow.addDigit(
                        context,
                        ref,
                        config,
                        digits[row * 3 + column],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: buttonSize + gap,
              child: config.isUnlock && biometricEnabled
                  ? _PadButton(
                      size: buttonSize,
                      icon: biometricIcon,
                      enabled: !disabled,
                      onTap: () =>
                          AuthFlow.promptBiometric(context, ref, config),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gap / 2),
              child: _PadButton(
                size: buttonSize,
                label: '0',
                enabled: !disabled,
                onTap: () => AuthFlow.addDigit(context, ref, config, '0'),
              ),
            ),
            SizedBox(
              width: buttonSize + gap,
              child: Align(
                alignment: Alignment.centerRight,
                child: _PadButton(
                  size: buttonSize,
                  icon: Icons.backspace_outlined,
                  enabled: !disabled,
                  onTap: () => AuthFlow.backspace(ref, config),
                ),
              ),
            ),
          ],
        ),
        if (config.isUnlock) ...[
          const SizedBox(height: 14),
          if (state.isRecoveringPin)
            const Text('Verifying...')
          else
            TextButton(
              onPressed: () => _showForgotPinDialog(context, ref),
              child: const Text('Forgot PIN?'),
            ),
        ],
      ],
    );
  }

  void _showForgotPinDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Forgot PIN?'),
        content: const Text(
          'Verify this device and your Google account before creating a new PIN. '
          'Your expense data will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              AuthFlow.recoverForgottenPin(context, ref, config);
            },
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.size,
    required this.enabled,
    required this.onTap,
    this.label,
    this.icon,
  });

  final double size;
  final bool enabled;
  final VoidCallback onTap;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label ?? 'Biometric authentication',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(size / 2),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? colors.surfaceContainerHighest.withValues(alpha: 0.72)
                  : colors.surfaceContainerHighest.withValues(alpha: 0.35),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: size * 0.34, color: colors.onSurface)
                  : Text(
                      label!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinIndicators extends StatelessWidget {
  const _PinIndicators({
    required this.pin,
    required this.isSubmitting,
    required this.colors,
  });

  final String pin;
  final bool isSubmitting;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    if (isSubmitting) {
      return const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = ((constraints.maxWidth - 32) / 4)
            .clamp(48.0, 62.0)
            .toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final filled = index < pin.length;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                width: boxWidth,
                height: boxWidth,
                decoration: BoxDecoration(
                  color: filled
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: filled
                        ? colors.primary
                        : colors.outlineVariant.withValues(alpha: 0.8),
                    width: filled ? 1.8 : 1.5,
                  ),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: filled
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
