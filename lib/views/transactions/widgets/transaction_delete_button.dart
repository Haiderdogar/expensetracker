import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_handler.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/transaction_provider.dart';
import '../transactions_ui_providers.dart';

class TransactionDeleteButton extends StatelessWidget {
  const TransactionDeleteButton({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isSaving = ref.watch(transactionFormProvider(transaction)).isSaving;
        return IconButton(
          icon: const Icon(Icons.delete),
          onPressed: isSaving ? null : () => _delete(context, ref),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction'),
        content: const Text('Delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final draft = ref.read(transactionFormProvider(transaction));
    ref.read(transactionFormProvider(transaction).notifier).state = draft.copyWith(isSaving: true);
    try {
      await ref.read(transactionsProvider.notifier).delete(transaction.id);
      if (context.mounted) Navigator.of(context).pop('deleted');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.message(error))));
      }
    } finally {
      if (context.mounted) {
        ref.read(transactionFormProvider(transaction).notifier).state =
            draft.copyWith(isSaving: false);
      }
    }
  }
}
