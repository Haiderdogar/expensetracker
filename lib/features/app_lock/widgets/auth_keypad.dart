import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../google_sign_in/providers/auth_provider.dart';
import '../providers/auth_flow.dart';
import '../providers/auth_ui_providers.dart';
import 'pin_pad_button.dart';

class AuthKeypad extends ConsumerWidget {
  const AuthKeypad({super.key, required this.config, required this.height});

  final AuthScreenConfig config;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
        final state = ref.watch(authUiStateProvider(config));
        final coolingDown = AuthFlow.isCoolingDown(state);
        final biometricEnabled = ref.watch(biometricEnabledProvider);
        final biometricIcon = state.biometricType?.name == 'face'
            ? Icons.face_rounded
            : Icons.fingerprint_rounded;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).viewPadding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: height,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1,
                  children: [
                    for (final digit in const ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      Center(
                        child: PinPadButton(
                          label: digit,
                          onTap: coolingDown
                              ? () {}
                              : () => AuthFlow.addDigit(context, ref, config, digit),
                        ),
                      ),
                    // Bottom Left: Biometric button (if available) or empty
                    Center(
                      child: config.isUnlock &&
                              biometricEnabled.value == true &&
                              state.biometricType != null
                          ? PinPadButton(
                              label: '',
                              icon: biometricIcon,
                              onTap: () => AuthFlow.promptBiometric(context, ref, config),
                            )
                          : const SizedBox(width: 76, height: 76),
                    ),
                    // Bottom Center: 0
                    Center(
                      child: PinPadButton(
                        label: '0',
                        onTap: coolingDown
                            ? () {}
                            : () => AuthFlow.addDigit(context, ref, config, '0'),
                      ),
                    ),
                    // Bottom Right: Backspace
                    Center(
                      child: PinPadButton(
                        label: '',
                        icon: Icons.backspace_outlined,
                        onTap: () => AuthFlow.backspace(ref, config),
                      ),
                    ),
                  ],
                ),
              ),
              if (config.isUnlock) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showForgotPinDialog(context, ref),
                  child: Text(
                    'Forgot PIN?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
  }

  void _showForgotPinDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.primaryEmerald),
            SizedBox(width: 10),
            Text('Forgot PIN?'),
          ],
        ),
        content: const Text(
          'This will remove your current PIN. You will be prompted to set up a new one the next time you open the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Wipe the stored PIN so the app re-routes to the setup flow.
              await ref.read(authControllerProvider.notifier).disablePin();
            },
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }
}
