import 'package:flutter/material.dart';

import 'widgets/add_budget_sheet.dart';
import 'widgets/budgets_app_bar.dart';
import 'widgets/budgets_content.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BudgetsAppBar(),
      body: const BudgetsContent(),
    );
  }

  static void showAddBudget(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBudgetSheet(),
    );
  }
}
