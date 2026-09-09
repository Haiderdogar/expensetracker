import 'package:flutter/material.dart';

class AppShellDrawerSectionTitle extends StatelessWidget {
  const AppShellDrawerSectionTitle({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text('Pages', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
  );
}
