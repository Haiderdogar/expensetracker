import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/global_keys.dart';
import '../../../providers/wallet_provider.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
      ),
      title: const _DashboardWalletTitle(),
    );
  }
}

class _DashboardWalletTitle extends StatelessWidget {
  const _DashboardWalletTitle();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final wallets = ref.watch(walletsProvider);
        final selectedWalletId = ref.watch(selectedWalletIdProvider);
        final walletName = wallets.maybeWhen(
          data: (items) {
            if (selectedWalletId != null) {
              for (final wallet in items) {
                if (wallet.id == selectedWalletId) return wallet.name;
              }
            }
            return items.isEmpty ? AppStrings.dashboard : items.first.name;
          },
          orElse: () => AppStrings.dashboard,
        );

        if (wallets.hasValue && selectedWalletId == null && wallets.requireValue.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ref.read(selectedWalletIdProvider.notifier).state = wallets.requireValue.first.id;
          });
        }
        return Text(walletName);
      },
    );
  }
}
