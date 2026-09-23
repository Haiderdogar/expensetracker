import 'package:flutter/material.dart';

import 'package:expensetracker/features/app_lock/providers/auth_flow.dart';
import 'package:expensetracker/features/app_lock/providers/auth_ui_providers.dart';
import 'package:expensetracker/features/app_lock/widgets/auth_header.dart';
import 'package:expensetracker/features/app_lock/widgets/auth_pin_input.dart';

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
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 40
                  ? constraints.maxHeight - 40
                  : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthHeader(config: config),
                const SizedBox(height: 18),
                AuthPinInput(config: config),
              ],
            ),
          ),
        );
      },
    );
  }
}
