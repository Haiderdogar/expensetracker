import 'package:flutter/material.dart';

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: const [
          DashboardSummaryCard(),
          SizedBox(height: 24),
          RecentTransactionsHeader(),
          SizedBox(height: 12),
          RecentTransactionsList(),
        ],
      ),
    );
  }
}
