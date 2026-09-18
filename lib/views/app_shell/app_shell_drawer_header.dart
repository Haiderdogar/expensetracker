import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/wallet_model.dart';
import '../../providers/wallet_provider.dart';
import 'app_shell_providers.dart';

class AppShellDrawerHeader extends ConsumerWidget {
  const AppShellDrawerHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appShellProfileProvider).value;
    final wallets = ref.watch(walletsProvider).value ?? const <WalletModel>[];
    final selectedWalletId = ref.watch(selectedWalletIdProvider);
    final selected = wallets.where((w) => w.id == selectedWalletId);
    final walletName = selected.isNotEmpty
        ? selected.first.name
        : (wallets.isNotEmpty ? wallets.first.name : 'Wallet');

    final name = profile?.name ?? '';
    final email = profile?.email ?? '';
    final photoUrl = profile?.photoUrl;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest.withValues(alpha: 0.6)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + name row ──────────────────────────────────────
          Row(
            children: [
              // Avatar with ring
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl),
                  backgroundColor: AppColors.primaryEmerald.withValues(
                    alpha: 0.12,
                  ),
                  child: photoUrl == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryEmerald,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Guest User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Divider ───────────────────────────────────────────────
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          // ── Active wallet chip ────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: AppColors.primaryEmerald,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  walletName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.incomeGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
