import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/wallet_provider.dart';
import '../../core/utils/global_keys.dart';
import '../transactions/add_transaction_screen.dart';
import 'widgets/dashboard_summary_card.dart';
import 'widgets/recent_transactions_list.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final selectedWalletId = ref.watch(selectedWalletIdProvider);
    final walletName = walletsAsync.maybeWhen(
      data: (wallets) {
        if (selectedWalletId != null) {
          for (final wallet in wallets) {
            if (wallet.id == selectedWalletId) return wallet.name;
          }
        }
        if (wallets.isNotEmpty) return wallets.first.name;
        return AppStrings.dashboard;
      },
      orElse: () => AppStrings.dashboard,
    );

    if (walletsAsync is AsyncData &&
        walletsAsync.value != null &&
        selectedWalletId == null &&
        walletsAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedWalletIdProvider.notifier).state =
            walletsAsync.value!.first.id;
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(walletName),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AddTransactionScreen(),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const DashboardSummaryCard(),
          const SizedBox(height: 24),
          Text(
            AppStrings.recentTransactions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const RecentTransactionsList(),
        ],
      ),
    );
  }
}
