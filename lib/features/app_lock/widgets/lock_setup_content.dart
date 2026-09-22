import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

class LockSetupContent extends StatelessWidget {
  const LockSetupContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(AppStrings.protectAppTitle, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(AppStrings.protectAppBody, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
      ],
    );
  }
}
