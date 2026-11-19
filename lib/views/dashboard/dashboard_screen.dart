import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../features/wallet_currency/providers/wallet_provider.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/dashboard_summary_card.dart';
import 'widgets/recent_transactions_header.dart';
import 'widgets/recent_transactions_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      body: const _DashboardRefreshBody(),
    );
  }
}

class _DashboardRefreshBody extends ConsumerWidget {
  const _DashboardRefreshBody();

  // Leave room for the standard 56px FAB, its 16px margin, and a 16px gap
  // between the final transaction and the button.
  static const _floatingActionButtonClearance = 88.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(walletsProvider.notifier).refresh(),
          ref.read(transactionsProvider.notifier).refresh(),
          ref.read(categoriesProvider.notifier).refresh(),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardSummaryCard(),
                  SizedBox(height: 5),
                  RecentTransactionsHeader(),
                ],
              ),
            ),
          ),
          const RecentTransactionsList(),
          SliverToBoxAdapter(
            // The shell extends content behind its bottom bar. Its inherited
            // bottom padding includes the actual loaded banner height.
            child: SizedBox(
              height:
                  MediaQuery.paddingOf(context).bottom +
                  _floatingActionButtonClearance,
            ),
          ),
        ],
      ),
    );
  }
}
