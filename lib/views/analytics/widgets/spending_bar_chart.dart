import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/backup_provider.dart';
import '../../../providers/auth_provider.dart';

class SpendingBarChart extends ConsumerWidget {
  const SpendingBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monthlySpendingTrendProvider);

    return trendAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(e.toString()),
      data: (trend) {
        if (trend.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No spending trend data')),
          );
        }

        final maxY = trend.map((e) => e.value).reduce((a, b) => a > b ? a : b);

        return SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.25,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  // build a simple tooltip text combining month and formatted value
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = trend[group.x.toInt()].key;
                    final value = trend[group.x.toInt()].value;
                    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
                    String subtitle = Formatters.currency(value, symbol: symbol);
                    // percentage change from previous month
                    if (group.x.toInt() > 0) {
                      final prev = trend[group.x.toInt() - 1].value;
                      if (prev > 0) {
                        final change = ((value - prev) / prev) * 100;
                        subtitle += '\n${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% vs prev';
                      }
                    }
                    return BarTooltipItem('$month\n$subtitle', TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color));
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(Formatters.currency(value, symbol: ref.watch(currencySymbolProvider).value ?? '\$'), style: const TextStyle(fontSize: 10));
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
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= trend.length) return const SizedBox();
                      final label = trend[i].key.substring(5);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(label, style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(trend.length, (i) {
                final val = trend[i].value;
                // color ramp based on value
                final hue = (120 - (i * 8)).clamp(0, 240).toDouble();
                final color = HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor();
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: val,
                      color: color,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
