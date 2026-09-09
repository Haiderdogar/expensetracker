import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final selected = wallets.where((wallet) => wallet.id == selectedWalletId);
    final walletName = selected.isNotEmpty ? selected.first.name : (wallets.isNotEmpty ? wallets.first.name : 'Wallet');
    final name = profile?.name ?? '';
    final email = profile?.email ?? '';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(width: double.infinity, margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.78)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18)), child: Row(children: [
      CircleAvatar(radius: 26, backgroundColor: Colors.white.withValues(alpha: 0.2), child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name.isNotEmpty ? name : 'Guest User', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(email.isNotEmpty ? email : 'Add your email', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.78))),
        const SizedBox(height: 5),
        Row(children: [Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.white.withValues(alpha: 0.78)), const SizedBox(width: 5), Expanded(child: Text(walletName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w600)))]),
      ])),
    ]));
  }
}
