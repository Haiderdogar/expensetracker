import 'package:flutter/material.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../transactions/add_transaction_screen.dart';

class DashboardAddTransactionButton extends StatelessWidget {
  const DashboardAddTransactionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton(
        heroTag: 'fab_dashboard',
        onPressed: () => _addTransaction(context),
        child: const Icon(Icons.add),
      ),
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
