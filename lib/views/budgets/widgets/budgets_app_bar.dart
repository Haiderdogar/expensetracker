import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/global_keys.dart';
import '../../../providers/budget_provider.dart';

class BudgetsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BudgetsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(AppStrings.budgets),
      actions: const [_BudgetsRefreshButton()],
    );
  }
}

class _BudgetsRefreshButton extends StatelessWidget {
  const _BudgetsRefreshButton();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(currentMonthBudgetProgressProvider),
      ),
    );
  }
}
