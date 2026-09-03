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
    final selectedTransactionFilter = ref.watch(
      recentTransactionFilterProvider,
    );
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
          heroTag: 'fab_dashboard',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.recentTransactions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedTransactionFilter,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Filter recent transactions',
                    icon: const Icon(Icons.filter_list),
                    color: Theme.of(context).colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    elevation: 6,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    menuPadding: const EdgeInsets.symmetric(vertical: 8),
                    initialValue: selectedTransactionFilter,
                    onSelected: (filter) {
                      ref.read(recentTransactionFilterProvider.notifier).state =
                          filter;
                    },
                    itemBuilder: (context) {
                      return recentTransactionFilterOptions.map((filter) {
                        return PopupMenuItem<String>(
                          value: filter,
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                filter == selectedTransactionFilter
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: filter == selectedTransactionFilter
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                filter,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight:
                                      filter == selectedTransactionFilter
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const RecentTransactionsList(),
        ],
      ),
    );
  }
}
