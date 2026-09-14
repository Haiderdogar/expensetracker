import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../auth_flow.dart';
import '../auth_ui_providers.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.config});

  final AuthScreenConfig config;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
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

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            children: [
              // Security Icon / Biometric glyph
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  biometricMode
                      ? biometricIcon
                      : (config.isSetup
                          ? Icons.shield_outlined
                          : Icons.lock_outline_rounded),
                  size: 32,
                  color: AppColors.primaryEmerald,
                ),
              ),
              const SizedBox(height: 18),

              // Step indicator if setting up PIN
              if (config.isSetup) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.isConfirmStep ? 'STEP 2 OF 2' : 'STEP 1 OF 2',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Title
              Text(
                biometricMode ? biometricTitle : title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              if (biometricMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => AuthFlow.usePin(context, ref, config),
                  icon: const Icon(Icons.pin_outlined, size: 18),
                  label: const Text(AppStrings.usePin),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
