import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../analytics_data_providers.dart';
import '../analytics_filters_provider.dart';

class SpendingBarChart extends ConsumerWidget {
  const SpendingBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(trendSeriesProvider);
    final filter = ref.watch(analyticsFilterProvider);
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final typeFilter = filter.trendType;
    final hasData = trend.any((t) => t.expense > 0 || t.income > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and Type Segmented Toggle (All, Expense, Income)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SegmentedButton<String>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStatePropertyAll(
                  const EdgeInsets.symmetric(horizontal: 6),
                ),
                side: WidgetStatePropertyAll(
                  BorderSide(
                    color: isDark ? Colors.white12 : AppColors.gray200,
                  ),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('All', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 'expense',
                  label: Text('Expense', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Income', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {typeFilter},
              onSelectionChanged: (selection) {
                ref
                    .read(analyticsFilterProvider.notifier)
                    .setTrendType(selection.first);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (!hasData) ...[
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.deepForest : AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 42,
                  color: isDark ? AppColors.gray600 : AppColors.gray400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No trend activity for this period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          _buildChart(context, trend, typeFilter, symbol, isDark),
        ],
      ],
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<TrendBucket> trend,
    String typeFilter,
    String symbol,
    bool isDark,
  ) {
    final maxYValue = trend.fold<double>(
      0.0,
      (max, entry) {
        if (typeFilter == 'expense') return entry.expense > max ? entry.expense : max;
        if (typeFilter == 'income') return entry.income > max ? entry.income : max;
        final highest = entry.expense > entry.income ? entry.expense : entry.income;
        return highest > max ? highest : max;
      },
    );

    final maxY = maxYValue == 0 ? 100.0 : maxYValue * 1.25;
    final length = trend.length;

    // Determine label skip interval to prevent collisions
    int skipInterval = 1;
    if (length > 20) {
      skipInterval = 5;
    } else if (length > 10) {
      skipInterval = 2;
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : AppColors.gray200,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (group.x.toInt() < 0 || group.x.toInt() >= trend.length) {
                  return null;
                }
                final item = trend[group.x.toInt()];
                final isExpenseRod = typeFilter == 'all'
                    ? rodIndex == 0
                    : typeFilter == 'expense';

                final label = isExpenseRod ? 'Expense' : 'Income';
                final amount = isExpenseRod ? item.expense : item.income;
                final subtitle =
                    '$label: ${Formatters.currency(amount, symbol: symbol)}';

                return BarTooltipItem(
                  '${item.tooltipDate}\n$subtitle',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value >= maxY * 0.98) return const SizedBox();
                  return Text(
                    _formatShortAmount(value, symbol),
                    style: const TextStyle(fontSize: 10, color: AppColors.gray400),
                  );
                },
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
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox();

                  // Skip intervals to prevent overlapping
                  if (skipInterval > 1 && (i % skipInterval != 0) && i != trend.length - 1) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      trend[i].label,
                      style: const TextStyle(fontSize: 10, color: AppColors.gray400),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(trend.length, (i) {
            final entry = trend[i];
            final rods = <BarChartRodData>[];

            final rodWidth = length <= 7 ? 14.0 : (length <= 15 ? 10.0 : 6.0);

            if (typeFilter == 'all') {
              rods.add(
                BarChartRodData(
                  toY: entry.expense,
                  color: AppColors.expenseRed,
                  width: rodWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              );
              rods.add(
                BarChartRodData(
                  toY: entry.income,
                  color: AppColors.incomeGreen,
                  width: rodWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              );
            } else {
              final val = typeFilter == 'expense' ? entry.expense : entry.income;
              rods.add(
                BarChartRodData(
                  toY: val,
                  color: typeFilter == 'expense'
                      ? AppColors.expenseRed
                      : AppColors.incomeGreen,
                  width: rodWidth * 1.5,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              );
            }

            return BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: rods,
            );
          }),
        ),
      ),
    );
  }

  String _formatShortAmount(double value, String symbol) {
    if (value >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(0)}k';
    }
    return '$symbol${value.toInt()}';
  }
}
