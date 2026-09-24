import 'package:flutter/material.dart';

import 'package:expensetracker/features/app_lock/widgets/lock_setup_actions.dart';
import 'package:expensetracker/features/app_lock/widgets/lock_setup_content.dart';

class LockSetupScreen extends StatelessWidget {
  const LockSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 10),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/lock_icon.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              semanticLabel: 'App lock',
                            ),
                            const SizedBox(height: 38),
                            const LockSetupContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 460),
                child: LockSetupActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
