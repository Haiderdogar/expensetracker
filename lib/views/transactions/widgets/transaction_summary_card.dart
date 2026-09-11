import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';

class TransactionSummaryCard extends ConsumerWidget {
  const TransactionSummaryCard({
    super.key,
    required this.transactions,
    required this.selectedType,
  });

  final List<TransactionModel> transactions;
  final String? selectedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final scheme = Theme.of(context).colorScheme;

    double totalInflow = 0;
    double totalOutflow = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        totalInflow += t.amount;
      } else {
        totalOutflow += t.amount;
      }
    }
    final net = totalInflow - totalOutflow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedType == 'income'
                    ? 'Income Summary'
                    : selectedType == 'expense'
                        ? 'Expense Summary'
                        : 'Overview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedType == null) ...[
            // All view: Inflow vs Outflow & Net
            Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    label: 'Income',
                    amount: totalInflow,
                    symbol: symbol,
                    color: AppColors.incomeGreen,
                    icon: Icons.south_west_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _MetricItem(
                    label: 'Expense',
                    amount: totalOutflow,
                    symbol: symbol,
                    color: AppColors.expenseRed,
                    icon: Icons.north_east_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _MetricItem(
                    label: 'Net',
                    amount: net,
                    symbol: symbol,
                    color: net >= 0
                        ? AppColors.incomeGreen
                        : AppColors.expenseRed,
                    icon: net >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    showSign: true,
                  ),
                ),
              ],
            ),
          ] else if (selectedType == 'income') ...[
            // Income section view
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Income',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(totalInflow, symbol: '$symbol '),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.incomeGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _MiniStat(
                    label: 'Average',
                    value: Formatters.currency(
                      transactions.isEmpty
                          ? 0
                          : totalInflow / transactions.length,
                      symbol: symbol,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Expense section view
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expense',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(totalOutflow, symbol: '$symbol '),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.expenseRed,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _MiniStat(
                    label: 'Average',
                    value: Formatters.currency(
                      transactions.isEmpty
                          ? 0
                          : totalOutflow / transactions.length,
                      symbol: symbol,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
    required this.icon,
    this.showSign = false,
  });

  final String label;
  final double amount;
  final String symbol;
  final Color color;
  final IconData icon;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefix = showSign ? (amount > 0 ? '+' : '') : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$prefix${Formatters.currency(amount, symbol: symbol)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
