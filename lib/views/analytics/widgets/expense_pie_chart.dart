import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/backup_provider.dart';

class ExpensePieChart extends ConsumerWidget {
  const ExpensePieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(expenseByCategoryProvider);

    return dataAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(e.toString()),
      data: (data) {
        if (data.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No expense data')),
          );
        }

        final entries = data.entries.toList();
        final total = entries.fold<double>(0, (s, e) => s + e.value);

        return SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                // Generate visually distinct palette using HSL hues
                final hue = (i * 360 / entries.length) % 360;
                final color = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
                final titleColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                return PieChartSectionData(
                  value: entry.value,
                  title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
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
        );
      },
    );
  }
}
