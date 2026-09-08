import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'add_budget_amount_field.dart';
import 'add_budget_category_selector.dart';
import 'add_budget_save_button.dart';

class AddBudgetSheet extends StatelessWidget {
  const AddBudgetSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _AddBudgetTitle(),
          SizedBox(height: 16),
          AddBudgetCategorySelector(),
          SizedBox(height: 12),
          AddBudgetAmountField(),
          SizedBox(height: 16),
          AddBudgetSaveButton(),
        ],
      ),
    );
  }
}

class _AddBudgetTitle extends StatelessWidget {
  const _AddBudgetTitle();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.addBudget, style: Theme.of(context).textTheme.titleMedium);
  }
}
