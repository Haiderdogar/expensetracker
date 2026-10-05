import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../views/app_shell/app_shell_navigation_metrics.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class GlassNavbar extends StatelessWidget {
  const GlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.bottomPadding,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        key: const ValueKey('glass-navbar-padding'),
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                key: const ValueKey('glass-navbar-surface'),
                height: AppShellNavigationMetrics.bottomNavigationBarHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.deepForest.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? AppColors.mintAccent.withValues(alpha: 0.2)
                        : AppColors.gray200.withValues(alpha: 0.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = index == currentIndex;
                    final color = selected
                        ? AppColors.primaryEmerald
                        : (isDark ? AppColors.gray400 : AppColors.gray600);

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              color: color,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
