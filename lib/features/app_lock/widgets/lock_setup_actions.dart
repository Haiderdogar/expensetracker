import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/core/constants/app_strings.dart';
import 'package:expensetracker/core/router/app_router.dart';
import 'package:expensetracker/features/google_sign_in/providers/auth_provider.dart';
import 'package:expensetracker/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';

class LockSetupActions extends ConsumerWidget {
  const LockSetupActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          label: AppStrings.setupAppLock,
          icon: Icons.lock_outline,
          onPressed: () => context.push<bool>(AppRoutes.pinSetup),
        ),
        const SizedBox(height: 12),
        CustomButton(
          label: AppStrings.skipForNow,
          isOutlined: true,
          onPressed: () async {
            try {
              await ref.read(authControllerProvider.notifier).skipLockSetup();
              if (context.mounted) context.go(AppRoutes.shell);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not save your lock preference.'),
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
