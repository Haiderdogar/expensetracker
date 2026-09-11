import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import 'budget_tile_menu.dart';

class BudgetProgressTile extends ConsumerWidget {
  const BudgetProgressTile({super.key, required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final percent = (progress.progress * 100).clamp(0, 100);
    final isOverBudget = progress.isOverBudget;
    final isNearLimit = progress.isNearLimit;

    final Color statusColor;
    if (isOverBudget) {
      statusColor = AppColors.expenseRed;
    } else if (isNearLimit) {
      statusColor = Colors.orange;
    } else {
      statusColor = AppColors.incomeGreen;
    }

    final categoryColor = progress.categoryColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar, Name, Status Badge & Menu
            Row(
              children: [
                // Category Icon Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    progress.categoryIcon,
                    size: 18,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 10),

                // Name and Spent / Budget Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.currency(progress.spent, symbol: symbol)} of ${Formatters.currency(progress.budget.amount, symbol: symbol)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Percentage and Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverBudget
                            ? '${Formatters.currency(progress.remaining.abs(), symbol: symbol)} over'
                            : '${Formatters.currency(progress.remaining, symbol: symbol)} left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),

                BudgetTileMenu(progress: progress),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: isDark ? Colors.white12 : AppColors.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
