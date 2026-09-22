import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/router/app_router.dart';

class TransactionsAddButton extends StatelessWidget {
  const TransactionsAddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'fab_transactions',
      onPressed: () => _addTransaction(context),
      child: const Icon(Icons.add),
    );
  }

  Future<void> _addTransaction(BuildContext context) async {
    final result = await context.push<String>(AppRoutes.transactionEditor);
    if (result == 'created' && context.mounted) {
      showSuccessSnackBar(context, 'Transaction added successfully');
    }
  }
}
