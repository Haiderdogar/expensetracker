import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../auth_screen.dart';

class LockSetupActions extends StatelessWidget {
  const LockSetupActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            label: AppStrings.setupAppLock,
            icon: Icons.lock_outline,
            onPressed: () => Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(builder: (_) => const AuthScreen(isSetup: true, offerBiometricAfterSetup: true)),
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: AppStrings.skipForNow,
            isOutlined: true,
            onPressed: () => ref.read(authControllerProvider.notifier).skipLockSetup(),
          ),
        ],
      ),
    );
  }
}
