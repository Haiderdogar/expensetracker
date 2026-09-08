import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'widgets/profile_body.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: const ProfileBody(),
    );
  }
}
