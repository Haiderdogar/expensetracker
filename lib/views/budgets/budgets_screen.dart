import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../providers/budget_provider.dart';
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
      appBar: AppBar(title: const Text(AppStrings.budgets)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => _showAddBudget(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            '$monthLabel ${AppStrings.monthlyBudgets}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          progressAsync.when(
            loading: () => const ShimmerList(itemCount: 3),
            error: (e, _) => Text(e.toString()),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No budgets set for this month'),
                  ),
                );
              }
              return Column(
                children: items
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BudgetProgressTile(progress: p),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
