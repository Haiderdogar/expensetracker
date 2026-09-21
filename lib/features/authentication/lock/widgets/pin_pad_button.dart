import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

const Map<String, String> _subLetters = {
  '1': '',
  '2': 'ABC',
  '3': 'DEF',
  '4': 'GHI',
  '5': 'JKL',
  '6': 'MNO',
  '7': 'PQRS',
  '8': 'TUV',
  '9': 'WXYZ',
  '0': '+',
};

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final letters = _subLetters[label] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? colors.surfaceContainerHighest.withValues(alpha: 0.45)
                : AppColors.gray100,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 26, color: colors.onSurface)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      if (letters.isNotEmpty)
                        Text(
                          letters,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
