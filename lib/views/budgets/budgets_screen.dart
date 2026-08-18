import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import '../../core/utils/formatters.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loader.dart';
import 'widgets/budget_progress_tile.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _showAddBudget(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddBudgetSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(currentMonthBudgetProgressProvider);
    final monthLabel = Formatters.monthYearLabel(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(AppStrings.budgets),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(currentMonthBudgetProgressProvider),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          heroTag: 'fab_budgets',
          onPressed: () => _showAddBudget(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentMonthBudgetProgressProvider);
          // Wait for provider to refresh so pull-to-refresh gives feedback
          await ref.watch(currentMonthBudgetProgressProvider.future).catchError((_) {});
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(
              '$monthLabel ${AppStrings.monthlyBudgets}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            progressAsync.when(
              loading: () => const ShimmerList(itemCount: 3),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Failed to load budgets: ${e.toString()}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(currentMonthBudgetProgressProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No budgets set for this month'),
                    ),
                  );
                }

                // Summary card
                final totalBudget = items.fold<double>(0, (s, i) => s + i.budget.amount);
                final totalSpent = items.fold<double>(0, (s, i) => s + i.spent);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Budgets', style: Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 4),
                                Text(Formatters.currency(totalBudget, symbol: ref.watch(currencySymbolProvider).value ?? '\$')),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Spent', style: Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 4),
                                Text(Formatters.currency(totalSpent, symbol: ref.watch(currencySymbolProvider).value ?? '\$')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BudgetProgressTile(progress: p),
                            ))
                        .toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
