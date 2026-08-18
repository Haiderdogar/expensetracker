import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import 'widgets/expense_pie_chart.dart';
import 'widgets/spending_bar_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(AppStrings.analytics),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            AppStrings.categoryBreakdown,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: ExpensePieChart(),
          )),
          const SizedBox(height: 24),
          Text(
            AppStrings.spendingTrend,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: SpendingBarChart(),
          )),
        ],
      ),
    );
  }
}
