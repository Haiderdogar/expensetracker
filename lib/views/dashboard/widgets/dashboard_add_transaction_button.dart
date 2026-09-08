import 'package:flutter/material.dart';

import '../../transactions/add_transaction_screen.dart';

class DashboardAddTransactionButton extends StatelessWidget {
  const DashboardAddTransactionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton(
        heroTag: 'fab_dashboard',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
