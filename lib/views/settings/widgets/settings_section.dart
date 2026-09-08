import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4, top: 2),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
          child: child,
        ),
      ],
    );
  }
}
