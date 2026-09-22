import 'package:expensetracker/views/dashboard/dashboard_screen.dart';
import 'package:expensetracker/views/dashboard/widgets/dashboard_app_bar.dart';
import 'package:expensetracker/views/dashboard/widgets/dashboard_summary_card.dart';
import 'package:expensetracker/views/dashboard/widgets/recent_transactions_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashboardScreen renders summary card and recent transactions without crashing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DashboardAppBar), findsOneWidget);
    expect(find.byType(DashboardSummaryCard), findsOneWidget);
    expect(find.byType(RecentTransactionsHeader), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
