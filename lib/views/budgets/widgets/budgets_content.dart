import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/budget_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import 'budget_progress_tile.dart';
import 'budget_summary_card.dart';

class BudgetsContent extends StatelessWidget {
  const BudgetsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final progress = ref.watch(currentMonthBudgetProgressProvider);
        return RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text(
                '${Formatters.monthYearLabel(DateTime.now())} ${AppStrings.monthlyBudgets}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              progress.when(
                loading: () => const ShimmerList(itemCount: 3),
                error: (error, _) => BudgetsLoadError(error: error),
                data: (items) {
                  if (items.isEmpty) return const BudgetsEmptyState();
                  final totalBudget = items.fold<double>(0, (sum, item) => sum + item.budget.amount);
                  final totalSpent = items.fold<double>(0, (sum, item) => sum + item.spent);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BudgetSummaryCard(totalBudget: totalBudget, totalSpent: totalSpent),
                      const SizedBox(height: 12),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
      },
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(currentMonthBudgetProgressProvider);
    await ref.read(currentMonthBudgetProgressProvider.future).catchError((_) {});
  }
}

class BudgetsEmptyState extends StatelessWidget {
  const BudgetsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('No budgets set for this month'),
      ),
    );
  }
}

class BudgetsLoadError extends StatelessWidget {
  const BudgetsLoadError({super.key, required this.error});

  final Object error;

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
                onPressed: () => ref.invalidate(currentMonthBudgetProgressProvider),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
