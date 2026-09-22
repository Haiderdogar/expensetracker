import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/auth_flow.dart';
import '../providers/auth_ui_providers.dart';

class AuthPinInput extends ConsumerWidget {
  const AuthPinInput({super.key, required this.config});

  final AuthScreenConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
        final state = ref.watch(authUiStateProvider(config));
        final pin = state.pin;
        final controller = ref.read(authPinControllerProvider(config));
        final focusNode = ref.read(authPinFocusNodeProvider(config));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).requestFocus(focusNode),
                child: _PinIndicators(
                  pin: pin,
                  isSubmitting: state.isSubmitting,
                ),
              ),
              // Hidden accessible TextField for hardware keyboard or autofill support
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 1,
                  width: 1,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (value) {
                      AuthFlow.updatePin(ref, config, value);
                      if (value.length == 4) {
                        AuthFlow.complete(context, ref, config);
                      }
                    },
                    onSubmitted: (_) => AuthFlow.complete(context, ref, config),
                    decoration: const InputDecoration.collapsed(hintText: ''),
                  ),
                ),
              ),
            ],
          ),
        );
  }
}

class _PinIndicators extends StatelessWidget {
  const _PinIndicators({
    required this.pin,
    required this.isSubmitting,
  });

  final String pin;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isSubmitting) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryEmerald,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < pin.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            width: filled ? 18 : 16,
            height: filled ? 18 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.primaryEmerald : Colors.transparent,
              border: Border.all(
                color: filled
                    ? AppColors.primaryEmerald
                    : colors.outlineVariant.withValues(alpha: 0.8),
                width: filled ? 0 : 2,
              ),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
