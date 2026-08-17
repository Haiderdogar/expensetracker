import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../widgets/custom_button.dart';

class BudgetProgressTile extends ConsumerWidget {
  const BudgetProgressTile({
    super.key,
    required this.progress,
  });

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final pct = (progress.progress * 100).clamp(0, 100);
    final overBudget = progress.spent > progress.budget.amount;
    final barColor = overBudget ? AppColors.expenseRed : AppColors.mintAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.categoryName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: overBudget ? AppColors.expenseRed : AppColors.primaryEmerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.gray200,
                color: barColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${Formatters.currency(progress.spent, symbol: symbol)} / '
              '${Formatters.currency(progress.budget.amount, symbol: symbol)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

final _addBudgetCategoryProvider =  StateProvider.autoDispose<String?>((ref) => null);
final _addBudgetAmountProvider = StateProvider.autoDispose<String>((ref) => '');
final _addBudgetLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

class AddBudgetSheet extends StatelessWidget {
  const AddBudgetSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final categories = ref.watch(expenseCategoriesProvider);
      final selectedCategory = ref.watch(_addBudgetCategoryProvider);
      final amount = ref.watch(_addBudgetAmountProvider);
      final loading = ref.watch(_addBudgetLoadingProvider);

      Future<void> save() async {
        if (selectedCategory == null || amount.isEmpty) return;
        ref.read(_addBudgetLoadingProvider.notifier).state = true;
        try {
          await ref.read(budgetsProvider.notifier).create(
                categoryId: selectedCategory,
                amount: double.parse(amount),
              );
          if (context.mounted) Navigator.of(context).pop();
        } finally {
          if (context.mounted) ref.read(_addBudgetLoadingProvider.notifier).state = false;
        }
      }

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
          children: [
            Text(AppStrings.addBudget, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            categories.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
              data: (cats) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(hintText: 'Category'),
                initialValue: selectedCategory,
                items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => ref.read(_addBudgetCategoryProvider.notifier).state = v,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Budget amount'),
              onChanged: (v) => ref.read(_addBudgetAmountProvider.notifier).state = v,
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: AppStrings.save,
              isLoading: loading,
              onPressed: save,
            ),
          ],
        ),
      );
    });
  }
}
