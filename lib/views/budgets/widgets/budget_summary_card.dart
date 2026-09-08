import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.totalBudget, required this.totalSpent});

  final double totalBudget;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BudgetSummaryValue(label: 'Total Budgets', value: Formatters.currency(totalBudget, symbol: symbol)),
                _BudgetSummaryValue(label: 'Spent', value: Formatters.currency(totalSpent, symbol: symbol), alignEnd: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BudgetSummaryValue extends StatelessWidget {
  const _BudgetSummaryValue({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
