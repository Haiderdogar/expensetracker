import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/router/app_router.dart';

class DashboardAddTransactionButton extends StatelessWidget {
  const DashboardAddTransactionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 75),
      child: FloatingActionButton(
        heroTag: 'fab_dashboard',
        onPressed: () => _addTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addTransaction(BuildContext context) async {
    final result = await context.push<String>(AppRoutes.transactionEditor);
    if (result == 'created' && context.mounted) {
      showSuccessSnackBar(context, 'Transaction added successfully');
    }
  }
}
