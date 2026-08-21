import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'auth_screen.dart';

class LockSetupScreen extends ConsumerWidget {
  const LockSetupScreen({super.key});

  Future<void> _setupLock(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AuthScreen(
          isSetup: true,
          offerBiometricAfterSetup: true,
        ),
      ),
    );
  }

  Future<void> _skip(WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).skipLockSetup();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.shield_outlined,
                size: 72,
                color: AppColors.primaryEmerald,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.protectAppTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.protectAppBody,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CustomButton(
                label: AppStrings.setupAppLock,
                icon: Icons.lock_outline,
                onPressed: () => _setupLock(context, ref),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: AppStrings.skipForNow,
                isOutlined: true,
                onPressed: () => _skip(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
