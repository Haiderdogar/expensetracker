import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../auth_flow.dart';
import '../auth_ui_providers.dart';
import 'pin_pad_button.dart';

class AuthKeypad extends StatelessWidget {
  const AuthKeypad({super.key, required this.config, required this.height});

  final AuthScreenConfig config;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(authUiStateProvider(config));
        final coolingDown = AuthFlow.isCoolingDown(state);
        final biometricEnabled = ref.watch(biometricEnabledProvider);
        final biometricIcon = state.biometricType?.name == 'face' ? Icons.face : Icons.fingerprint;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewPadding.bottom + 36),
          child: SizedBox(
            height: height,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                for (final digit in const ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                  Center(child: PinPadButton(label: digit, onTap: coolingDown ? () {} : () => AuthFlow.addDigit(context, ref, config, digit))),
                Center(
                  child: config.isUnlock && biometricEnabled.value == true && state.biometricType != null
                      ? PinPadButton(label: '', icon: biometricIcon, onTap: () => AuthFlow.promptBiometric(context, ref, config))
                      : const SizedBox(width: 72, height: 72),
                ),
                Center(child: PinPadButton(label: '0', onTap: coolingDown ? () {} : () => AuthFlow.addDigit(context, ref, config, '0'))),
                Center(child: PinPadButton(label: '', icon: Icons.backspace_outlined, onTap: () => AuthFlow.backspace(ref, config))),
              ],
            ),
          ),
        );
      },
    );
  }
}
