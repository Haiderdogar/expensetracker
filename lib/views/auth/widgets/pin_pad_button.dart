import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PinPadButton extends StatelessWidget {
  const PinPadButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: AppColors.primaryEmerald.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 28, color: AppColors.primaryEmerald)
                : Text(
                    label,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
          ),
        ),
      ),
    );
  }
}
