import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import '../budgets_ui_providers.dart';

class AddBudgetCategorySelector extends StatelessWidget {
  const AddBudgetCategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final categories = ref.watch(expenseCategoriesProvider);
        final selectedCategory = ref.watch(addBudgetCategoryProvider);
        return categories.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(error.toString()),
          data: (items) {
            if (items.isEmpty) return const Text('No expense categories yet.');
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map(
                (category) => _BudgetCategoryChip(
                  category: category,
                  selected: selectedCategory == category.id,
                ),
              ).toList(),
            );
          },
        );
      },
    );
  }
}

class _BudgetCategoryChip extends StatelessWidget {
  const _BudgetCategoryChip({required this.category, required this.selected});

  final CategoryModel category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => GestureDetector(
        onLongPress: () => _deleteCategory(context, ref),
        child: ChoiceChip(
          label: Text(category.name),
          selected: selected,
          onSelected: (_) => ref.read(addBudgetCategoryProvider.notifier).state = category.id,
        ),
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete "${category.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoriesProvider.notifier).delete(category.id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
