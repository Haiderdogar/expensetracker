import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'widgets/lock_setup_actions.dart';
import 'widgets/lock_setup_content.dart';

class LockSetupScreen extends StatelessWidget {
  const LockSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Spacer(),
              Icon(Icons.shield_outlined, size: 72, color: AppColors.primaryEmerald),
              SizedBox(height: 24),
              LockSetupContent(),
              Spacer(),
              LockSetupActions(),
            ],
          ),
        ),
      ),
    );
  }
}
