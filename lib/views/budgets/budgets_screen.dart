import 'package:flutter/material.dart';

import 'widgets/add_budget_sheet.dart';
import 'widgets/budgets_add_button.dart';
import 'widgets/budgets_app_bar.dart';
import 'widgets/budgets_content.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BudgetsAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: BudgetsAddButton(onPressed: () => _showAddBudget(context)),
      body: const BudgetsContent(),
    );
  }

  void _showAddBudget(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddBudgetSheet(),
    );
  }
}
