import 'package:flutter/material.dart';

import '../../../core/utils/app_snackbars.dart';
import '../add_transaction_screen.dart';

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
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result == 'created' && context.mounted) {
      showSuccessSnackBar(context, 'Transaction added successfully');
    }
  }
}
