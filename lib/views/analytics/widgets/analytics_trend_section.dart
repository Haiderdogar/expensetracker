import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../analytics_filters_provider.dart';
import 'analytics_chart_section.dart';
import 'spending_bar_chart.dart';

class AnalyticsTrendSection extends StatelessWidget {
  const AnalyticsTrendSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsChartSection(
      title: AppStrings.spendingTrend,
      filterProvider: trendAnalyticsFilterProvider,
      chartBuilder: (typeFilter, rangeStart, rangeEnd) => SpendingBarChart(
        typeFilter: typeFilter,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }
}
