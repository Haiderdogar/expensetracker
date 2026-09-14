import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class DrawerItem extends StatelessWidget {
  const DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = AppColors.primaryEmerald.withValues(alpha: isDark ? 0.18 : 0.1);
    final defaultBg = isDark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
        : colors.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? selectedBg : defaultBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primaryEmerald.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryEmerald.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.3 : 0.15)
                        : colors.surfaceContainerHighest.withValues(alpha: isDark ? 0.6 : 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: isSelected
                        ? AppColors.primaryEmerald
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? AppColors.mintAccent : AppColors.primaryEmerald)
                          : colors.onSurface,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isSelected
                      ? AppColors.primaryEmerald
                      : colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
