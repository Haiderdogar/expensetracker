import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../models/transaction_model.dart';
import 'widgets/transaction_delete_button.dart';
import 'widgets/transaction_form.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key, this.transaction});

  final TransactionModel? transaction;

  @override
  Widget build(BuildContext context) {
    final isEditing = transaction != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit ${_capitalize(transaction!.type)}'
              : AppStrings.addTransaction,
        ),
        actions: isEditing ? [TransactionDeleteButton(transaction: transaction!)] : null,
      ),
      body: TransactionForm(transaction: transaction),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
