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
        final biometricIcon = state.biometricType?.name == 'face' ? Icons.face : Icons.fingerprint;
        final biometricTitle = state.biometricType?.name == 'face' ? AppStrings.unlockWithFace : AppStrings.unlockWithFingerprint;
        final title = config.verifyOnly
            ? AppStrings.enterPin
            : config.isSetup
            ? state.isConfirmStep ? AppStrings.confirmPin : AppStrings.createPin
            : AppStrings.enterPin;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.12)),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Icon(biometricMode ? biometricIcon : Icons.lock, size: 44, color: AppColors.primaryEmerald),
              ),
              const SizedBox(height: 20),
              Text(biometricMode ? biometricTitle : title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              if (biometricMode) ...[
                const SizedBox(height: 8),
                Text(AppStrings.unlockWithBiometric, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () => AuthFlow.usePin(context, ref, config), child: const Text(AppStrings.usePin)),
              ] else if (config.isUnlock) ...[
                const SizedBox(height: 8),
                Text(AppStrings.unlockSubtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            ],
          ),
        );
      },
    );
  }
}
