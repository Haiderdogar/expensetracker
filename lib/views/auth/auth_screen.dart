import 'package:flutter/material.dart';

import 'auth_flow.dart';
import 'auth_ui_providers.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_keypad.dart';
import 'widgets/auth_pin_input.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    this.isSetup = false,
    this.verifyOnly = false,
    this.offerBiometricAfterSetup = false,
  });

  final bool isSetup;
  final bool verifyOnly;
  final bool offerBiometricAfterSetup;

  @override
  Widget build(BuildContext context) {
    final config = AuthScreenConfig(
      isSetup: isSetup,
      verifyOnly: verifyOnly,
      offerBiometricAfterSetup: offerBiometricAfterSetup,
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: (isSetup || verifyOnly) && Navigator.of(context).canPop()
          ? AppBar(backgroundColor: Colors.transparent, elevation: 0)
          : null,
      body: SafeArea(
        child: _AuthScreenBody(config: config),
      ),
    );
  }
}

class _AuthScreenBody extends StatelessWidget {
  const _AuthScreenBody({required this.config});

  final AuthScreenConfig config;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keypadHeight = (constraints.maxHeight * 0.4).clamp(324.0, 440.0).toDouble();
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                AuthHeader(config: config),
                const SizedBox(height: 24),
                AuthPinInput(config: config),
                AuthKeypad(config: config, height: keypadHeight),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
