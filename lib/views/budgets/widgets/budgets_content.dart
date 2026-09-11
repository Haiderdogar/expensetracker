import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/budget_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../budgets_ui_providers.dart';
import 'add_budget_sheet.dart';
import 'budget_progress_tile.dart';
import 'budget_summary_card.dart';
import 'budgets_month_selector.dart';

class BudgetsContent extends ConsumerWidget {
  const BudgetsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final progress = ref.watch(monthBudgetProgressProvider(selectedMonth));

    return RefreshIndicator(
      onRefresh: () => _refresh(ref, selectedMonth),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Month Navigator (< Month Year >)
          const BudgetsMonthSelector(),
          const SizedBox(height: 12),

          // Budget Content / Progress List
          progress.when(
            loading: () => const ShimmerList(itemCount: 3),
            error: (error, _) => BudgetsLoadError(error: error, month: selectedMonth),
            data: (items) {
              if (items.isEmpty) {
                return BudgetsEmptyState(month: selectedMonth);
              }

              final totalBudget =
                  items.fold<double>(0, (sum, item) => sum + item.budget.amount);
              final totalSpent =
                  items.fold<double>(0, (sum, item) => sum + item.spent);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BudgetSummaryCard(
                    totalBudget: totalBudget,
                    totalSpent: totalSpent,
                  ),
                  const SizedBox(height: 12),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BudgetProgressTile(progress: item),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref, DateTime month) async {
    ref.invalidate(monthBudgetProgressProvider(month));
    try {
      await ref.read(monthBudgetProgressProvider(month).future);
    } catch (_) {}
  }
}

class BudgetsEmptyState extends ConsumerWidget {
  const BudgetsEmptyState({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final prevBudgetsAsync = ref.watch(monthBudgetProgressProvider(prevMonth));
    final hasPrevBudgets = (prevBudgetsAsync.value ?? []).isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No budgets for ${Formatters.monthYearLabel(month)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Set spending limits to stay on track and save more money.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddBudgetSheet(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Budget'),
                ),
                if (hasPrevBudgets) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _copyFromLastMonth(context, ref),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Last Month'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyFromLastMonth(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref
          .read(budgetsProvider.notifier)
          .copyFromPreviousMonth(month);
      ref.invalidate(monthBudgetProgressProvider(month));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied $count budget(s) from last month')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy: $e')),
        );
      }
    }
  }
}

class BudgetsLoadError extends StatelessWidget {
  const BudgetsLoadError({super.key, required this.error, required this.month});

  final Object error;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Failed to load budgets: $error'),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () =>
                    ref.invalidate(monthBudgetProgressProvider(month)),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
