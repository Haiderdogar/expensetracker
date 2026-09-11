import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/category_utils.dart';
import '../../../models/category_model.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/category_provider.dart';
import '../budgets_ui_providers.dart';

class AddBudgetCategorySelector extends ConsumerWidget {
  const AddBudgetCategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(expenseCategoriesProvider);
    final selectedCategory = ref.watch(addBudgetCategoryProvider);
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgets = ref.watch(monthBudgetProgressProvider(selectedMonth)).value ?? [];
    final existingBudgetCategoryIds =
        budgets.map((b) => b.budget.categoryId).toSet();

    return categories.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(error.toString()),
      data: (items) {
        if (items.isEmpty) {
          return const Text('No expense categories available.');
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((category) {
            final isSelected = selectedCategory == category.id;
            final hasBudget = existingBudgetCategoryIds.contains(category.id);
            final color = categoryColorFromHex(category.color);
            final icon = categoryIconFromName(category.icon);

            return ChoiceChip(
              avatar: Icon(icon, size: 16, color: isSelected ? null : color),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.name),
                  if (hasBudget) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_outline, size: 13),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (_) {
                ref.read(addBudgetCategoryProvider.notifier).state = category.id;
                // If a budget already exists, prefill its amount for convenience
                if (hasBudget) {
                  final existing =
                      budgets.where((b) => b.budget.categoryId == category.id).firstOrNull;
                  if (existing != null) {
                    ref.read(addBudgetAmountProvider.notifier).state =
                        existing.budget.amount.toStringAsFixed(0);
                  }
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}
