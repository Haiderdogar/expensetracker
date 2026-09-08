import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import 'budget_tile_menu.dart';

class BudgetProgressTile extends StatelessWidget {
  const BudgetProgressTile({super.key, required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).clamp(0, 100);
    final isOverBudget = progress.spent > progress.budget.amount;
    final barColor = isOverBudget ? AppColors.expenseRed : AppColors.mintAccent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(progress.categoryName, style: Theme.of(context).textTheme.titleSmall)),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isOverBudget ? AppColors.expenseRed : AppColors.primaryEmerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                BudgetTileMenu(progress: progress),
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
            _BudgetAmountLabel(progress: progress),
            if (isOverBudget) ...[
              const SizedBox(height: 8),
              const BudgetStatusLabel(label: 'Over budget', color: AppColors.expenseRed, weight: FontWeight.bold),
            ] else if (progress.remaining / progress.budget.amount <= 0.1) ...[
              const SizedBox(height: 8),
              const BudgetStatusLabel(label: 'Near budget limit', color: Colors.orange, weight: FontWeight.w600),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetAmountLabel extends StatelessWidget {
  const _BudgetAmountLabel({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
        return Text(
          '${Formatters.currency(progress.spent, symbol: symbol)} / ${Formatters.currency(progress.budget.amount, symbol: symbol)}',
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}

class BudgetStatusLabel extends StatelessWidget {
  const BudgetStatusLabel({super.key, required this.label, required this.color, required this.weight});

  final String label;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(color: color, fontWeight: weight));
  }
}
