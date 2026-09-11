import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../providers/budget_provider.dart';
import '../../../widgets/custom_button.dart';
import '../budgets_ui_providers.dart';

class AddBudgetSaveButton extends ConsumerWidget {
  const AddBudgetSaveButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(addBudgetLoadingProvider);
    return CustomButton(
      label: AppStrings.save,
      isLoading: isLoading,
      onPressed: () => _save(context, ref),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final categoryId = ref.read(addBudgetCategoryProvider);
    final amountText = ref.read(addBudgetAmountProvider);
    final selectedMonth = ref.read(selectedBudgetMonthProvider);

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }

    ref.read(addBudgetLoadingProvider.notifier).state = true;
    try {
      await ref.read(budgetsProvider.notifier).create(
            categoryId: categoryId,
            amount: parsedAmount,
            month: selectedMonth,
          );
      ref.invalidate(monthBudgetProgressProvider(selectedMonth));
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save budget: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        ref.read(addBudgetLoadingProvider.notifier).state = false;
      }
    }
  }
}
