import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../app_shell.dart';
import 'widgets/pin_pad_button.dart';

final _pinProvider = StateProvider.autoDispose<String>((ref) => '');
final _firstPinProvider = StateProvider.autoDispose<String?>((ref) => null);
final _errorProvider = StateProvider.autoDispose<String?>((ref) => null);
final _isConfirmStepProvider = StateProvider.autoDispose<bool>((ref) => false);

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, this.isSetup = false});

  final bool isSetup;

  String _title(bool isSetup, bool isConfirm) {
    if (isSetup) {
      return isConfirm ? AppStrings.confirmPin : AppStrings.createPin;
    }
    return AppStrings.enterPin;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final pin = ref.watch(_pinProvider);
        final error = ref.watch(_errorProvider);
        final isConfirmStep = ref.watch(_isConfirmStepProvider);
        final biometricAsync = ref.watch(biometricEnabledProvider);

        Future<void> handleComplete(WidgetRef ref, BuildContext context) async {
          final currentPin = ref.read(_pinProvider);
          if (currentPin.length != 4) return;

          if (isSetup) {
            if (!ref.read(_isConfirmStepProvider)) {
              ref.read(_firstPinProvider.notifier).state = currentPin;
              ref.read(_pinProvider.notifier).state = '';
              ref.read(_isConfirmStepProvider.notifier).state = true;
              return;
            }

            final firstPin = ref.read(_firstPinProvider);
            if (firstPin == null || currentPin != firstPin) {
              ref.read(_errorProvider.notifier).state = AppStrings.pinMismatch;
              ref.read(_pinProvider.notifier).state = '';
              ref.read(_firstPinProvider.notifier).state = null;
              ref.read(_isConfirmStepProvider.notifier).state = false;
              return;
            }

            await ref
                .read(authControllerProvider.notifier)
                .setupPin(currentPin);
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const AppShell()),
              );
            }
            return;
          }

          final valid = await ref
              .read(authControllerProvider.notifier)
              .verifyPin(currentPin);
          if (!valid) {
            ref.read(_errorProvider.notifier).state = AppStrings.wrongPin;
            ref.read(_pinProvider.notifier).state = '';
            return;
          }
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const AppShell()),
            );
          }
        }

        void onDigit(String digit) {
          if (ref.read(_pinProvider).length >= 4) return;
          ref.read(_pinProvider.notifier).state =
              ref.read(_pinProvider) + digit;
          ref.read(_errorProvider.notifier).state = null;
          if (ref.read(_pinProvider).length == 4) handleComplete(ref, context);
        }

        void onBackspace() {
          final current = ref.read(_pinProvider);
          if (current.isEmpty) return;
          ref.read(_pinProvider.notifier).state = current.substring(
            0,
            current.length - 1,
          );
          ref.read(_errorProvider.notifier).state = null;
        }

        Future<void> tryBiometric() async {
          final success = await ref
              .read(authControllerProvider.notifier)
              .authenticateWithBiometric();
          if (success && context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const AppShell()),
            );
          }
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppColors.primaryEmerald,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _title(isSetup, isConfirmStep),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? AppColors.primaryEmerald
                              : AppColors.gray200,
                        ),
                      );
                    }),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(color: AppColors.expenseRed),
                    ),
                  ],
                  const Spacer(),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
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
                        PinPadButton(label: d, onTap: () => onDigit(d)),
                      if (!isSetup)
                        biometricAsync.when(
                          data: (enabled) => enabled
                              ? PinPadButton(
                                  label: '',
                                  icon: Icons.fingerprint,
                                  onTap: tryBiometric,
                                )
                              : const SizedBox(width: 72, height: 72),
                          loading: () => const SizedBox(width: 72, height: 72),
                          error: (_, _) =>
                              const SizedBox(width: 72, height: 72),
                        )
                      else
                        const SizedBox(width: 72, height: 72),
                      PinPadButton(label: '0', onTap: () => onDigit('0')),
                      PinPadButton(
                        label: '',
                        icon: Icons.backspace_outlined,
                        onTap: onBackspace,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
