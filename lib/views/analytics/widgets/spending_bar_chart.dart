import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';

class SpendingBarChart extends ConsumerWidget {
  const SpendingBarChart({
    super.key,
    required this.typeFilter,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final String typeFilter;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';

    return transactionsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(e.toString()),
      data: (transactions) {
        final trend = _buildTrend(transactions);

        if (trend.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No spending trend data')),
          );
        }

        final maxYValue = trend.fold<double>(
          0,
          (max, entry) => [
            max,
            entry.expense,
            entry.income,
          ].reduce((a, b) => a > b ? a : b),
        );
        final maxY = maxYValue == 0 ? 1.0 : maxYValue * 1.25;

        return SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = trend[group.x.toInt()];
                    final selectedValue = typeFilter == 'all'
                        ? (rodIndex == 0 ? item.expense : item.income)
                        : (typeFilter == 'expense' ? item.expense : item.income);
                    final label = typeFilter == 'all'
                        ? (rodIndex == 0 ? 'Expense' : 'Income')
                        : (typeFilter == 'expense' ? 'Expense' : 'Income');
                    String subtitle = '$label: ${Formatters.currency(selectedValue, symbol: symbol)}';
                    if (group.x.toInt() > 0) {
                      final previous = typeFilter == 'all'
                          ? (rodIndex == 0
                              ? trend[group.x.toInt() - 1].expense
                              : trend[group.x.toInt() - 1].income)
                          : (typeFilter == 'expense'
                              ? trend[group.x.toInt() - 1].expense
                              : trend[group.x.toInt() - 1].income);
                      if (previous > 0) {
                        final change = ((selectedValue - previous) / previous) * 100;
                        subtitle += '\n${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% vs prev';
                      }
                    }
                    return BarTooltipItem(
                      '${item.detailLabel}\n$subtitle',
                      TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        Formatters.currency(value, symbol: symbol),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 64,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= trend.length) return const SizedBox();
                      final label = trend[i].label;
                      return Transform.rotate(
                        angle: -0.75,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(trend.length, (i) {
                final entry = trend[i];
                final rods = <BarChartRodData>[];
                if (typeFilter == 'all') {
                  rods.add(
                    BarChartRodData(
                      toY: entry.expense,
                      color: Colors.red.shade400,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  );
                  rods.add(
                    BarChartRodData(
                      toY: entry.income,
                      color: Colors.green.shade400,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  );
                } else {
                  final value = typeFilter == 'expense' ? entry.expense : entry.income;
                  rods.add(
                    BarChartRodData(
                      toY: value,
                      color: typeFilter == 'expense'
                          ? Colors.red.shade400
                          : Colors.green.shade400,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  );
                }

                return BarChartGroupData(
                  x: i,
                  barsSpace: typeFilter == 'all' ? 6 : 0,
                  barRods: rods,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  List<_TrendPoint> _buildTrend(List<TransactionModel> transactions) {
    final totals = <String, _TrendPoint>{};
    final useDailyBuckets = rangeEnd.difference(rangeStart).inDays <= 31;

    for (final tx in transactions) {
      final txDate = DateTime.tryParse(tx.date);
      if (txDate == null) {
        continue;
      }

      final effectiveEnd = rangeEnd
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));
      if (txDate.isBefore(rangeStart) || txDate.isAfter(effectiveEnd)) {
        continue;
      }

      if (typeFilter != 'all' && tx.type != typeFilter) {
        continue;
      }

      final bucketKey = useDailyBuckets
          ? tx.date.substring(0, 10)
          : tx.date.substring(0, 7);
      final existing = totals[bucketKey] ?? _TrendPoint(
            key: bucketKey,
            label: _formatBucketLabel(bucketKey, useDailyBuckets, short: true),
            detailLabel: _formatBucketLabel(bucketKey, useDailyBuckets, short: false),
          );
      if (tx.isExpense) {
        existing.expense += tx.amount;
      }
      if (tx.isIncome) {
        existing.income += tx.amount;
      }
      totals[bucketKey] = existing;
    }

    final trend = totals.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return trend;
  }

  String _formatBucketLabel(
    String bucketKey,
    bool useDailyBuckets, {
    required bool short,
  }) {
    if (useDailyBuckets) {
      final date = DateTime.tryParse(bucketKey);
      if (date == null) {
        return bucketKey;
      }
      return short
          ? '${date.day}/${date.month}'
          : '${date.day}/${date.month}/${date.year}';
    }

    final date = DateTime.tryParse('$bucketKey-01');
    if (date == null) {
      return bucketKey;
    }
    return short ? '${date.month}/${date.year}' : '${date.month}/${date.year}';
  }
}

class _TrendPoint {
  _TrendPoint({required this.key, required this.label, required this.detailLabel});

  final String key;
  final String label;
  final String detailLabel;
  double expense = 0;
  double income = 0;
}
