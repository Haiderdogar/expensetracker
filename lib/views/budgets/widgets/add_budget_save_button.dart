import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../providers/budget_provider.dart';
import '../../../widgets/custom_button.dart';
import '../budgets_ui_providers.dart';

class AddBudgetSaveButton extends StatelessWidget {
  const AddBudgetSaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isLoading = ref.watch(addBudgetLoadingProvider);
        return CustomButton(
          label: AppStrings.save,
          isLoading: isLoading,
          onPressed: () => _save(context, ref),
        );
      },
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final categoryId = ref.read(addBudgetCategoryProvider);
    final amount = ref.read(addBudgetAmountProvider);
    if (categoryId == null || amount.isEmpty) return;
    ref.read(addBudgetLoadingProvider.notifier).state = true;
    try {
      await ref.read(budgetsProvider.notifier).create(categoryId: categoryId, amount: double.parse(amount));
      if (context.mounted) Navigator.of(context).pop();
    } finally {
      if (context.mounted) ref.read(addBudgetLoadingProvider.notifier).state = false;
    }
  }
}
