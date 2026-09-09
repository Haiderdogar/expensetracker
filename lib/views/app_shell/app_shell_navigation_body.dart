import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_screen.dart';
import '../budgets/budgets_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import 'app_shell_providers.dart';

class AppShellNavigationBody extends ConsumerWidget {
  const AppShellNavigationBody({super.key});

  static const _screens = [DashboardScreen(), TransactionsScreen(), AnalyticsScreen(), BudgetsScreen()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(appShellNavigationIndexProvider);
    final visited = ref.watch(appShellVisitedIndexesProvider);
    return IndexedStack(
      index: index,
      children: [
        for (var i = 0; i < _screens.length; i++)
          visited.contains(i) ? _screens[i] : const SizedBox.shrink(),
      ],
    );
  }
}
