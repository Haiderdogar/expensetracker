import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../auth_flow.dart';
import '../auth_ui_providers.dart';

class AuthPinInput extends StatelessWidget {
  const AuthPinInput({super.key, required this.config});

  final AuthScreenConfig config;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final pin = ref.watch(authUiStateProvider(config).select((state) => state.pin));
        final controller = ref.read(authPinControllerProvider(config));
        final focusNode = ref.read(authPinFocusNodeProvider(config));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).requestFocus(focusNode),
                child: _PinIndicators(pin: pin),
              ),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    onChanged: (value) {
                      AuthFlow.updatePin(ref, config, value);
                      if (value.length == 4) AuthFlow.complete(context, ref, config);
                    },
                    onSubmitted: (_) => AuthFlow.complete(context, ref, config),
                    decoration: const InputDecoration.collapsed(hintText: ''),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _PinIndicators extends StatelessWidget {
  const _PinIndicators({required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Row(
        key: ValueKey(pin),
        children: List.generate(4, (index) {
          final filled = index < pin.length;
          final focused = index == pin.length;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 4, right: index == 3 ? 0 : 4),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: filled ? AppColors.primaryEmerald : focused ? AppColors.primaryEmerald.withValues(alpha: 0.28) : AppColors.gray200,
                    width: filled ? 2 : 1.2,
                  ),
                ),
                child: Center(
                  child: filled
                      ? const SizedBox(width: 12, height: 12, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryEmerald)))
                      : focused ? Container(width: 2, height: 24, color: AppColors.primaryEmerald) : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
