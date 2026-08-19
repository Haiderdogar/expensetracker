import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';

class ExpensePieChart extends ConsumerWidget {
  const ExpensePieChart({
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return transactionsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(e.toString()),
      data: (transactions) {
        final categories = categoriesAsync.value ?? const <CategoryModel>[];
        final filtered = transactions.where((tx) {
          if (typeFilter != 'all' && tx.type != typeFilter) {
            return false;
          }
          final txDate = DateTime.tryParse(tx.date);
          if (txDate == null) {
            return false;
          }
          final effectiveEnd = rangeEnd
              .add(const Duration(days: 1))
              .subtract(const Duration(microseconds: 1));
          return !txDate.isBefore(rangeStart) && !txDate.isAfter(effectiveEnd);
        }).toList();

        final totals = <String, double>{};
        for (final tx in filtered) {
          String name = 'Uncategorized';
          for (final category in categories) {
            if (category.id == tx.categoryId) {
              name = category.name;
              break;
            }
          }
          totals[name] = (totals[name] ?? 0) + tx.amount;
        }

        final entries = totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (entries.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No data for this time range')),
          );
        }

        final total = entries.fold<double>(
          0,
          (sum, entry) => sum + entry.value,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 42,
                  sections: List.generate(entries.length, (i) {
                    final entry = entries[i];
                    final hue = (i * 360 / entries.length) % 360;
                    final color = HSLColor.fromAHSL(
                      1.0,
                      hue,
                      0.6,
                      0.5,
                    ).toColor();
                    final titleColor = color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white;
                    return PieChartSectionData(
                      value: entry.value,
                      title:
                          '${(entry.value / total * 100).toStringAsFixed(0)}%',
                      color: color,
                      radius: 60,
                      titleStyle: TextStyle(
                        color: titleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final hue = (index * 360 / entries.length) % 360;
                final color = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
                final percent = total == 0 ? 0.0 : (item.value / total) * 100;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.key} ${percent.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
