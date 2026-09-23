import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/auth_flow.dart';
import '../providers/auth_ui_providers.dart';

class AuthHeader extends ConsumerWidget {
  const AuthHeader({super.key, required this.config});

  final AuthScreenConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authUiStateProvider(config));
    if (config.isUnlock && !state.didPromptBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) AuthFlow.startBiometric(context, ref, config);
      });
    }
    final biometricMode = config.isUnlock && state.isBiometricMode;
    final biometricIcon = state.biometricType?.name == 'face'
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;
    final biometricTitle = state.biometricType?.name == 'face'
        ? AppStrings.unlockWithFace
        : AppStrings.unlockWithFingerprint;

        final title = config.verifyOnly
            ? 'Verify Current PIN'
            : config.isSetup
                ? (state.isConfirmStep ? 'Confirm Your PIN' : 'Create Security PIN')
                : 'Enter Your PIN';

        final subtitle = biometricMode
            ? AppStrings.unlockWithBiometric
            : config.verifyOnly
                ? 'Enter your current 4-digit PIN to proceed'
                : config.isSetup
                    ? (state.isConfirmStep
                        ? 'Re-enter your 4-digit PIN to verify'
                        : 'Choose a 4-digit PIN to secure your data')
                    : AppStrings.unlockSubtitle;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryEmerald.withValues(alpha: 0.16),
                colors.surfaceContainerHighest.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primaryEmerald.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  biometricMode
                      ? biometricIcon
                      : (config.isSetup
                            ? Icons.shield_outlined
                            : Icons.lock_outline_rounded),
                  size: 36,
                  color: AppColors.primaryEmerald,
                ),
              ),
              const SizedBox(height: 18),

              if (config.isSetup)
                Text(
                  state.isConfirmStep ? 'STEP 2 OF 2' : 'STEP 1 OF 2',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                biometricMode ? biometricTitle : title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (biometricMode) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => AuthFlow.usePin(context, ref, config),
                  icon: const Icon(Icons.pin_outlined, size: 18),
                  label: const Text(AppStrings.usePin),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
