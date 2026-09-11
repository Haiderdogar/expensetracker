import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../budgets_ui_providers.dart';

class BudgetsMonthSelector extends ConsumerWidget {
  const BudgetsMonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final theme = Theme.of(context);

    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Month Button
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous month',
              onPressed: () {
                final prev = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                  1,
                );
                ref.read(selectedBudgetMonthProvider.notifier).state = prev;
              },
            ),

            // Center Month/Year Title + "Current" jump chip
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  Formatters.monthYearLabel(selectedMonth),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isCurrentMonth) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref.read(selectedBudgetMonthProvider.notifier).state =
                          DateTime(now.year, now.month, 1);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Next Month Button
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next month',
              onPressed: () {
                final next = DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                  1,
                );
                ref.read(selectedBudgetMonthProvider.notifier).state = next;
              },
            ),
          ],
        ),
      ),
    );
  }
}
