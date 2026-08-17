import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../transactions/add_transaction_screen.dart';
import 'widgets/dashboard_summary_card.dart';
import 'widgets/recent_transactions_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dashboard)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
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
