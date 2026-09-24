import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset(
                'assets/lock_icon.png',
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                semanticLabel: 'App lock',
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (config.isSetup || config.verifyOnly)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        config.isSetup
                            ? (state.isConfirmStep
                                  ? 'STEP 2 OF 2'
                                  : 'STEP 1 OF 2')
                            : 'VERIFICATION',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    biometricMode ? biometricTitle : title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        if (biometricMode) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => AuthFlow.usePin(context, ref, config),
              icon: const Icon(Icons.pin_outlined, size: 18),
              label: const Text(AppStrings.usePin),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
