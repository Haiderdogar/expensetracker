import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../analytics_filters_provider.dart';
import 'analytics_chart_section.dart';
import 'expense_pie_chart.dart';

class AnalyticsCategorySection extends StatelessWidget {
  const AnalyticsCategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsChartSection(
      title: AppStrings.categoryBreakdown,
      filterProvider: categoryAnalyticsFilterProvider,
      chartBuilder: (typeFilter, rangeStart, rangeEnd) => ExpensePieChart(
        typeFilter: typeFilter,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }
}
