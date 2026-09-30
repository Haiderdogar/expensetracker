import 'dart:math' as math;

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
    final symbol = ref.watch(currencySymbolProvider).value ?? r'$';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final typeFilter = filter.trendType;
    final hasData = trend.any((t) => t.expense > 0 || t.income > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: title + segmented filter
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
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 6),
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

        const SizedBox(height: 10),

        // Colour legend only visible in "All" mode
        if (typeFilter == 'all')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _LegendDot(color: AppColors.expenseRed, label: 'Expense'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.incomeGreen, label: 'Income'),
              ],
            ),
          ),

        // Chart or empty-state
        if (!hasData)
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
          )
        else
          _BarChartBody(
            trend: trend,
            typeFilter: typeFilter,
            symbol: symbol,
            isDark: isDark,
          ),
      ],
    );
  }
}

// Internal chart body widget

class _BarChartBody extends StatefulWidget {
  const _BarChartBody({
    required this.trend,
    required this.typeFilter,
    required this.symbol,
    required this.isDark,
  });

  final List<TrendBucket> trend;
  final String typeFilter;
  final String symbol;
  final bool isDark;

  @override
  State<_BarChartBody> createState() => _BarChartBodyState();
}

class _BarChartBodyState extends State<_BarChartBody> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollToEndIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _BarChartBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trend.length != widget.trend.length ||
        oldWidget.typeFilter != widget.typeFilter) {
      _scrollToEndIfNeeded();
    }
  }

  void _scrollToEndIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.trend.length;
    final isAllMode = widget.typeFilter == 'all';

    // Geometry configuration:
    // - In 'all' mode: 2 rods (Expense & Income) side-by-side with a distinct gap (barsGap = 5.0)
    // - Proper left and right margins for each bar group
    const double rodWidthAll = 8.0;
    const double barsGapAll = 5.0; // Spacing between Income and Expense rods
    const double singleRodWidth = 14.0;

    // Desired group width + spacing
    // For 'all' mode: 8 + 5 + 8 = 21px rods width + ~20px margins = ~41px per bucket
    // For single mode: 14px rod width + ~22px margins = ~36px per bucket
    final double groupPlotWidth = isAllMode
        ? (2 * rodWidthAll) + barsGapAll + 20.0
        : singleRodWidth + 22.0;

    // Left reserved axis width is not needed in the scrolling chart now
    final double desiredContentWidth = groupPlotWidth * length;

    // Y-axis ceiling
    final maxYValue = widget.trend.fold<double>(0.0, (max, entry) {
      if (widget.typeFilter == 'expense') {
        return entry.expense > max ? entry.expense : max;
      }
      if (widget.typeFilter == 'income') {
        return entry.income > max ? entry.income : max;
      }
      final highest =
          entry.expense > entry.income ? entry.expense : entry.income;
      return highest > max ? highest : max;
    });
    final maxY = maxYValue == 0 ? 100.0 : maxYValue * 1.25;

    // Build bar groups with proper spacing between bars and margins
    final groups = List.generate(length, (i) {
      final entry = widget.trend[i];
      final rods = <BarChartRodData>[];

      if (isAllMode) {
        // Rod 0 = Expense (Left)
        rods.add(
          BarChartRodData(
            toY: entry.expense,
            gradient: _barGradient(AppColors.expenseRed),
            width: rodWidthAll,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        );
        // Rod 1 = Income (Right) — clearly separated with barsGapAll
        rods.add(
          BarChartRodData(
            toY: entry.income,
            gradient: _barGradient(AppColors.incomeGreen),
            width: rodWidthAll,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        );
      } else {
        final val = widget.typeFilter == 'expense'
            ? entry.expense
            : entry.income;
        final color = widget.typeFilter == 'expense'
            ? AppColors.expenseRed
            : AppColors.incomeGreen;
        rods.add(
          BarChartRodData(
            toY: val,
            gradient: _barGradient(color),
            width: singleRodWidth,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(5),
            ),
          ),
        );
      }

      return BarChartGroupData(
        x: i,
        // Gap between the two rods (Expense & Income) within this group
        barsSpace: isAllMode ? barsGapAll : 0,
        barRods: rods,
      );
    });

    const double chartHeight = 230.0;
    const double bottomReservedSize = 32.0;
    const double plotHeight = chartHeight - bottomReservedSize; // 198.0
    const double yAxisWidth = 44.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed vertical money count on the left (never scrolls)
        _FixedYAxis(
          maxY: maxY,
          symbol: widget.symbol,
          height: chartHeight,
          plotHeight: plotHeight,
          width: yAxisWidth,
        ),

        // Scrollable or adaptive chart plot on the right
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final needsScroll = desiredContentWidth > availableWidth;
              final chartWidth = needsScroll
                  ? math.max(desiredContentWidth, availableWidth)
                  : availableWidth;

              // Skip intervals only when non-scrollable and crowded
              int skipInterval = 1;
              if (!needsScroll && length > 14) {
                skipInterval = 4;
              } else if (!needsScroll && length > 7) {
                skipInterval = 2;
              }

              final chart = SizedBox(
                width: chartWidth,
                height: chartHeight,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    // spaceEvenly distributes groups with equal margins on the left and right of every group
                    alignment: BarChartAlignment.spaceEvenly,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: widget.isDark ? Colors.white10 : AppColors.gray200,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipBorderRadius: BorderRadius.circular(10),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final i = group.x;
                          if (i < 0 || i >= widget.trend.length) return null;
                          final item = widget.trend[i];

                          if (isAllMode) {
                            final net = item.income - item.expense;
                            return BarTooltipItem(
                              '${item.tooltipDate}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Expense: ${Formatters.currency(item.expense, symbol: widget.symbol)}\n',
                                  style: const TextStyle(
                                    color: AppColors.expenseRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Income: ${Formatters.currency(item.income, symbol: widget.symbol)}\n',
                                  style: const TextStyle(
                                    color: AppColors.incomeGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Net: ${net >= 0 ? '+' : ''}${Formatters.currency(net, symbol: widget.symbol)}',
                                  style: TextStyle(
                                    color: net >= 0
                                        ? AppColors.incomeGreen
                                        : AppColors.expenseRed,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          }

                          // Single-series tooltip
                          final isExpense = widget.typeFilter == 'expense';
                          final amount = isExpense ? item.expense : item.income;
                          return BarTooltipItem(
                            '${item.tooltipDate}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '${isExpense ? 'Expense' : 'Income'}: ${Formatters.currency(amount, symbol: widget.symbol)}',
                                style: TextStyle(
                                  color: isExpense
                                      ? AppColors.expenseRed
                                      : AppColors.incomeGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      // Left titles are now rendered in the fixed _FixedYAxis widget
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
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
                          reservedSize: bottomReservedSize,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= length) {
                              return const SizedBox();
                            }
                            // When not scrollable and many buckets, skip some labels to prevent collision
                            if (!needsScroll &&
                                skipInterval > 1 &&
                                (i % skipInterval != 0) &&
                                i != length - 1) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                widget.trend[i].label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.gray400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: groups,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              );

              if (!needsScroll) {
                return chart;
              }

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: chart,
              );
            },
          ),
        ),
      ],
    );
  }

  // Top-to-bottom gradient for each bar
  LinearGradient _barGradient(Color base) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [base, base.withValues(alpha: 0.65)],
      );
}

// Fixed Y-Axis widget on the left side (never scrolls)

class _FixedYAxis extends StatelessWidget {
  const _FixedYAxis({
    required this.maxY,
    required this.symbol,
    required this.height,
    required this.plotHeight,
    required this.width,
  });

  final double maxY;
  final String symbol;
  final double height;
  final double plotHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (maxY <= 0) return SizedBox(width: width, height: height);

    const fractions = [0.75, 0.50, 0.25, 0.0];

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: fractions.map((frac) {
          final value = maxY * frac;
          final lineY = (1.0 - frac) * plotHeight;
          final top = frac == 0.0 ? lineY - 13.0 : lineY - 7.0;

          return Positioned(
            top: top,
            right: 8,
            child: Text(
              _formatShortAmount(value, symbol),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.gray400,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
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

// Colour legend dot

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
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
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      );
}

