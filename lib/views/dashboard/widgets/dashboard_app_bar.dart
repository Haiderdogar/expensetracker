import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/global_keys.dart';
import '../../../features/wallet_currency/providers/wallet_provider.dart';

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

/// Shows the single wallet name as a static title (no switcher needed).
class _DashboardWalletTitle extends ConsumerWidget {
  const _DashboardWalletTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    final walletName = walletsAsync.maybeWhen(
      data: (items) => items.isNotEmpty ? items.first.name : AppStrings.dashboard,
      orElse: () => AppStrings.dashboard,
    );

    return Text(
      walletName,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      overflow: TextOverflow.ellipsis,
    );
  }
}
