import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../analytics_data_providers.dart';
import '../analytics_filters_provider.dart';
import 'analytics_category_list.dart';

class ExpensePieChart extends ConsumerStatefulWidget {
  const ExpensePieChart({super.key});

  @override
  ConsumerState<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends ConsumerState<ExpensePieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(categoryBreakdownProvider);
    final filter = ref.watch(analyticsFilterProvider);
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = breakdown.items;
    final total = breakdown.total;
    final isExpense = filter.categoryType == 'expense';

    if (_touchedIndex != null && _touchedIndex! >= items.length) {
      _touchedIndex = null;
    }

    final touchedItem =
        (_touchedIndex != null &&
            _touchedIndex! >= 0 &&
            _touchedIndex! < items.length)
        ? items[_touchedIndex!]
        : null;

    final centerTitle = touchedItem != null
        ? touchedItem.category.name
        : (isExpense ? 'Total Expense' : 'Total Income');

    final centerAmount = touchedItem != null ? touchedItem.amount : total;

    final centerSubtitle = touchedItem != null && total > 0
        ? '${touchedItem.percentage.toStringAsFixed(1)}%'
        : '${items.length} ${items.length == 1 ? 'category' : 'categories'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and Type Segmented Toggle (Expense vs Income)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SegmentedButton<String>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                side: WidgetStatePropertyAll(
                  BorderSide(
                    color: isDark ? Colors.white12 : AppColors.gray200,
                  ),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Expense', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Income', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {filter.categoryType},
              onSelectionChanged: (selection) {
                setState(() => _touchedIndex = null);
                ref
                    .read(analyticsFilterProvider.notifier)
                    .setCategoryType(selection.first);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (items.isEmpty) ...[
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
                  Icons.pie_chart_outline_rounded,
                  size: 42,
                  color: isDark ? AppColors.gray600 : AppColors.gray400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No ${isExpense ? 'expense' : 'income'} data for this period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Donut Chart
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2.5,
                    centerSpaceRadius: 64,
                    sections: List.generate(items.length, (i) {
                      final isTouched = i == _touchedIndex;
                      final item = items[i];
                      final showTitle = isTouched || item.percentage >= 7.0;

                      return PieChartSectionData(
                        value: item.amount,
                        title: '${item.percentage.toStringAsFixed(0)}%',
                        color: item.color,
                        radius: isTouched ? 34 : 28,
                        showTitle: showTitle,
                        titleStyle: TextStyle(
                          color: item.color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontSize: isTouched ? 12 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                ),
                // Donut Center Content
                GestureDetector(
                  onTap: () {
                    setState(() => _touchedIndex = null);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.gray400
                                : AppColors.gray600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.currency(centerAmount, symbol: symbol),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          centerSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: touchedItem != null
                                ? touchedItem.color
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Tiles
          AnalyticsCategoryList(
            items: items,
            selectedIndex: _touchedIndex,
            onSelect: (index) {
              setState(() => _touchedIndex = index);
            },
          ),
        ],
      ],
    );
  }
}
