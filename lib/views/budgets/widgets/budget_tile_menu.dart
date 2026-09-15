import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/budget_provider.dart';
import '../budgets_ui_providers.dart';

class BudgetTileMenu extends ConsumerWidget {
  const BudgetTileMenu({super.key, required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'edit') return _edit(context, ref);
    return _delete(context, ref);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: progress.budget.amount.toStringAsFixed(0),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditBudgetDialog(
        categoryName: progress.categoryName,
        controller: controller,
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty) return;

    final parsedAmount = double.tryParse(result);
    if (parsedAmount == null || parsedAmount <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid positive number')),
        );
      }
      return;
    }

    try {
      await ref.read(budgetsProvider.notifier).upsert(
            progress.budget.copyWith(amount: parsedAmount),
          );
      final selectedMonth = ref.read(selectedBudgetMonthProvider);
      ref.invalidate(monthBudgetProgressProvider(selectedMonth));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $error')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete budget'),
        content: Text('Delete budget for "${progress.categoryName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(budgetsProvider.notifier).delete(progress.budget.id);
      final selectedMonth = ref.read(selectedBudgetMonthProvider);
      ref.invalidate(monthBudgetProgressProvider(selectedMonth));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $error')),
        );
      }
    }
  }
}

class _EditBudgetDialog extends StatelessWidget {
  const _EditBudgetDialog({
    required this.categoryName,
    required this.controller,
  });

  final String categoryName;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit budget for $categoryName'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'New budget amount',
          labelText: 'Amount',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

