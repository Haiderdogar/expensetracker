import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'app_shell_drawer_header.dart';
import 'app_shell_drawer_pages.dart';
import 'app_shell_drawer_section_title.dart';
import 'app_shell_logout_button.dart';

class AppShellDrawer extends StatelessWidget {
  const AppShellDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark
          ? AppColors.deepForest
          : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top accent bar ─────────────────────────────────────────
          Container(
            height: MediaQuery.of(context).padding.top + 4,
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald.withValues(alpha: 0.06),
            ),
          ),
          // ── App branding strip ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Text(
                  'Expense Tracker',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                // Close button
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          // ── Profile card ───────────────────────────────────────────
          const AppShellDrawerHeader(),
          const SizedBox(height: 16),
          // ── Section label ──────────────────────────────────────────
          const AppShellDrawerSectionTitle(),
          const SizedBox(height: 8),
          // ── Nav items ──────────────────────────────────────────────
          const Expanded(child: AppShellDrawerPages()),
          // ── Logout ─────────────────────────────────────────────────
          const AppShellLogoutButton(),
        ],
      ),
    );
  }
}
