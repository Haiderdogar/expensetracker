import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../features/wallet_currency/providers/wallet_provider.dart';
import 'widgets/dashboard_add_transaction_button.dart';
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const DashboardAddTransactionButton(),
      body: const _DashboardRefreshBody(),
    );
  }
}

class _DashboardRefreshBody extends ConsumerWidget {
  const _DashboardRefreshBody();

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
      child: const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardSummaryCard(),
                  SizedBox(height: 20),
                  RecentTransactionsHeader(),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
          RecentTransactionsList(),
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
