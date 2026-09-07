import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

class AnalyticsTimeRangeFilter extends StatelessWidget {
  const AnalyticsTimeRangeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const ranges = [
      (AppStrings.day, 'day'),
      (AppStrings.week, 'week'),
      (AppStrings.month, 'month'),
      (AppStrings.threeMonths, 'quarter'),
      (AppStrings.customRange, 'custom'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ranges
            .map(
              (range) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(range.$1),
                  selected: selected == range.$2,
                  onSelected: (_) => onChanged(range.$2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
