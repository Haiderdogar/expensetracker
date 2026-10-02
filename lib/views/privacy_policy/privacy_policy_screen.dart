import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          AppStrings.privacyPolicy,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // ── Header card ───────────────────────────────────────────
            _HeaderCard(isDark: isDark, colors: colors, theme: theme),
            const SizedBox(height: 24),

            // ── Policy sections ───────────────────────────────────────
            _PolicySection(
              icon: Icons.info_outline_rounded,
              title: '1. Information We Collect',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'We collect only the information necessary to provide '
                  'you with a personalised expense‑tracking experience:\n\n'
                  '• **Account data** – Your name and email address obtained '
                  'through Google Sign-In.\n\n'
                  '• **Financial data** – Transactions, categories, budgets, '
                  'and notes that you manually enter into the app.\n\n'
                  '• **Device data** – Anonymous crash reports and basic '
                  'performance metrics to help us improve stability.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.storage_outlined,
              title: '2. How We Store Your Data',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'Your financial data is stored primarily on your device '
                  'using an encrypted local database. When you are online, '
                  'data is synchronised to your private Firestore document, '
                  'which is accessible only by your authenticated account.\n\n'
                  'We never sell, rent, or share your personal financial data '
                  'with third parties.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.lock_outline_rounded,
              title: '3. Data Security',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'We implement industry‑standard safeguards to protect '
                  'your information:\n\n'
                  '• Local data is encrypted using SQLite encryption.\n\n'
                  '• Cloud data is protected by Firebase Security Rules that '
                  'strictly limit access to your own user ID.\n\n'
                  '• Optional PIN and biometric locks add an additional layer '
                  'of protection on your device.\n\n'
                  'No security system is completely impenetrable, but we are '
                  'committed to keeping your data as safe as possible.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.people_outline_rounded,
              title: '4. Third-Party Services',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'This app integrates with the following third-party '
                  'services, each governed by their own privacy policies:\n\n'
                  '• **Google Sign-In** – Used for account authentication.\n\n'
                  '• **Firebase / Firestore** – Used for cloud storage and '
                  'real-time synchronisation.\n\n'
                  '• **Firebase Crashlytics** – Used for anonymous crash '
                  'reporting to improve app stability.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.manage_accounts_outlined,
              title: '5. Your Rights & Control',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'You are in full control of your data at all times:\n\n'
                  '• **Export** – Export all your data as a file from Settings.\n\n'
                  '• **Delete records** – Deleting a transaction, category, or budget '
                  'removes it from both local storage and the cloud.\n\n'
                  '• **Log out** – Logging out stops cloud sync. '
                  'Your local data remains on-device until you uninstall the app.\n\n'
                  '• **Delete Account** – You can permanently delete your account '
                  'and all associated data directly from Settings → Account. '
                  'This removes everything — see Section 5a for full details.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.delete_forever_rounded,
              title: '5a. Account Deletion',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'You may permanently delete your account at any time from '
                  '**Settings → Account → Delete Account**.\n\n'
                  '**What is deleted:**\n\n'
                  '• All transactions, categories, budgets, wallets, and notes '
                  'stored in the cloud (Firestore).\n\n'
                  '• Your Google profile information saved in the app.\n\n'
                  '• Your Firebase Authentication account.\n\n'
                  '• All local app data and security credentials (PIN, biometric) '
                  'stored on your device.\n\n'
                  '**How deletion works:**\n\n'
                  'For your security, deletion requires you to re-verify your '
                  'Google account. You will also be asked to type the word '
                  '"DELETE" to confirm — this prevents accidental account loss.\n\n'
                  '**⚠ This action is irreversible.** Once confirmed, your data '
                  'cannot be recovered. We recommend exporting your data first '
                  'if you wish to keep a local copy.\n\n'
                  'If deletion fails due to a network issue, your account and '
                  'data remain intact and you may try again.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.child_care_outlined,
              title: "6. Children's Privacy",
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'This app is not directed at children under the age of '
                  '13. We do not knowingly collect personal information from '
                  'children. If you believe a child has provided us with '
                  'personal information, please contact us so we can remove it.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.update_rounded,
              title: '7. Changes to This Policy',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'We may update this Privacy Policy from time to time. '
                  'When we do, the "Effective date" at the top of the page '
                  'will be revised. Continued use of the app after changes '
                  'constitutes your acceptance of the updated policy.',
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.mail_outline_rounded,
              title: '8. Contact Us',
              isDark: isDark,
              colors: colors,
              theme: theme,
              content:
                  'If you have any questions or concerns about this '
                  'Privacy Policy or the way we handle your data, please '
                  'reach out to us at:\n\n'
                  '📧  support@expensee.app',
            ),
            const SizedBox(height: 24),

            // ── Footer ────────────────────────────────────────────────
            Center(
              child: Text(
                'Effective date: 01 October 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isDark,
    required this.colors,
    required this.theme,
  });

  final bool isDark;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primaryEmerald.withValues(alpha: 0.18),
                  AppColors.primaryEmerald.withValues(alpha: 0.06),
                ]
              : [
                  AppColors.primaryEmerald.withValues(alpha: 0.10),
                  AppColors.primaryEmerald.withValues(alpha: 0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryEmerald.withValues(
            alpha: isDark ? 0.22 : 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald.withValues(
                alpha: isDark ? 0.22 : 0.12,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 28,
              color: AppColors.primaryEmerald,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.mintAccent
                        : AppColors.primaryEmerald,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We are committed to protecting your personal and financial information.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Policy Section ────────────────────────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.content,
    required this.isDark,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String content;
  final bool isDark;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryEmerald),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(
                alpha: isDark ? 0.15 : 0.3,
              ),
            ),
            const SizedBox(height: 14),
            // Section body — parse basic **bold** markdown
            _RichContent(content: content, theme: theme, colors: colors),
          ],
        ),
      ),
    );
  }
}

// ── Rich Content (basic **bold** parsing) ─────────────────────────────────────

class _RichContent extends StatelessWidget {
  const _RichContent({
    required this.content,
    required this.theme,
    required this.colors,
  });

  final String content;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
      height: 1.6,
      letterSpacing: 0.1,
    );

    // Split by **...** and build TextSpans
    final parts = content.split('**');
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (i.isOdd) {
        // Bold segment
        spans.add(
          TextSpan(
            text: parts[i],
            style: baseStyle?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: parts[i]));
      }
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
