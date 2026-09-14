import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../models/transaction_model.dart';
import 'transactions_ui_providers.dart';
import 'widgets/transaction_delete_button.dart';
import 'widgets/transaction_form.dart';

class AddTransactionScreen extends ConsumerWidget {
  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialType,
  });

  final TransactionModel? transaction;
  final String? initialType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialType != null && transaction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(transactionInitialTypeProvider) != initialType) {
          ref.read(transactionInitialTypeProvider.notifier).state = initialType!;
        }
      });
    }
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
