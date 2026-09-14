import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../app_shell/app_shell_providers.dart';

class DashboardBudgetSnapshot extends ConsumerWidget {
  const DashboardBudgetSnapshot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(currentMonthBudgetProgressProvider);
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return progressAsync.maybeWhen(
      data: (budgets) {
        if (budgets.isEmpty) {
          return _buildNoBudgetsCard(context, ref, colors, isDark);
        }

        final totalBudget = budgets.fold<double>(0.0, (s, b) => s + b.budget.amount);
        final totalSpent = budgets.fold<double>(0.0, (s, b) => s + b.spent);
        final progressRatio = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
        final clampedProgress = progressRatio.clamp(0.0, 1.0);
        final remaining = totalBudget - totalSpent;
        final isOver = totalSpent > totalBudget;
        final isNear = !isOver && progressRatio >= 0.8;
        final overCount = budgets.where((b) => b.isOverBudget).length;

        final barColor = isOver
            ? AppColors.expenseRed
            : (isNear ? Colors.orange : AppColors.primaryEmerald);

        return Card(
          elevation: 0,
          color: isDark
              ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
              : AppColors.gray100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.6),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToBudgets(ref),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.savings_outlined, size: 20, color: barColor),
                          const SizedBox(width: 8),
                          Text(
                            'Monthly Budget',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: barColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(progressRatio * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: barColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: clampedProgress,
                      minHeight: 8,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${Formatters.currency(totalSpent, symbol: '$symbol ')} spent of ${Formatters.currency(totalBudget, symbol: symbol)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isOver
                            ? 'Over by ${Formatters.currency(totalSpent - totalBudget, symbol: symbol)}'
                            : (overCount > 0
                                ? '$overCount over limit'
                                : '${Formatters.currency(remaining, symbol: symbol)} left'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOver || overCount > 0
                              ? AppColors.expenseRed
                              : (isNear ? Colors.orange : AppColors.incomeGreen),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildNoBudgetsCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      color: isDark
          ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
          : AppColors.gray100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToBudgets(ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  size: 20,
                  color: AppColors.primaryEmerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No monthly budget set',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set category budgets to track spending',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBudgets(WidgetRef ref) {
    ref.read(appShellNavigationIndexProvider.notifier).state = 3;
    ref.read(appShellVisitedIndexesProvider.notifier).update((v) => {...v, 3});
  }
}
