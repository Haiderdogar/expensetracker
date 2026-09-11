import 'package:expensetracker/views/analytics/analytics_screen.dart';
import 'package:expensetracker/views/analytics/widgets/analytics_category_section.dart';
import 'package:expensetracker/views/analytics/widgets/analytics_summary_cards.dart';
import 'package:expensetracker/views/analytics/widgets/analytics_time_range_filter.dart';
import 'package:expensetracker/views/analytics/widgets/analytics_trend_section.dart';
import 'package:expensetracker/views/analytics/widgets/expense_pie_chart.dart';
import 'package:expensetracker/views/analytics/widgets/spending_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnalyticsScreen renders all key components without crashing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsTimeRangeFilter), findsOneWidget);
    expect(find.byType(AnalyticsSummaryCards), findsOneWidget);
    expect(find.byType(AnalyticsCategorySection), findsOneWidget);
    expect(find.byType(ExpensePieChart), findsOneWidget);
    expect(find.byType(AnalyticsTrendSection), findsOneWidget);
    expect(find.byType(SpendingBarChart), findsOneWidget);
  });
}
