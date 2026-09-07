import 'package:flutter/material.dart';

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
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added')),
      );
    }
  }
}
