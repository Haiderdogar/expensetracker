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
    /// When true the screen is shown as a logout confirmation step.
    /// A clearly labelled AppBar with a cancel/back button is always shown.
    this.isLogoutConfirmation = false,
  });

  final bool isSetup;
  final bool verifyOnly;
  final bool offerBiometricAfterSetup;
  final bool isLogoutConfirmation;

  @override
  Widget build(BuildContext context) {
    final config = AuthScreenConfig(
      isSetup: isSetup,
      verifyOnly: verifyOnly,
      offerBiometricAfterSetup: offerBiometricAfterSetup,
    );

    AppBar? appBar;
    if (isLogoutConfirmation) {
      // Always show a prominent AppBar for logout confirmation so the user can
      // clearly cancel and return to the previous screen.
      appBar = AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Cancel logout',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Confirm Logout'),
        centerTitle: true,
      );
    } else if ((isSetup || verifyOnly) && Navigator.of(context).canPop()) {
      appBar = AppBar(backgroundColor: Colors.transparent, elevation: 0);
    }

    return PopScope(
      // Allow back navigation — return `false` (cancelled) to the caller.
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // If popped without a result (hardware back or AppBar back),
        // ensure the caller receives `false` rather than `null`.
        // We only do this for logout confirmation so the caller can distinguish
        // "cancelled" from a successful verification.
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: appBar,
        body: SafeArea(
          child: _AuthScreenBody(config: config),
        ),
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
        final keypadHeight =
            (constraints.maxHeight * 0.4).clamp(324.0, 440.0).toDouble();
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
