import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../add_transaction_screen.dart';
import '../transactions_ui_providers.dart';
import 'transaction_tile.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final transactions = ref.watch(
          filteredTransactionsProvider(
            type: ref.watch(transactionTypeFilterProvider),
            search: ref.watch(transactionSearchProvider),
            categories: ref.watch(transactionCategoryFilterProvider),
          ),
        );
        return transactions.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerList(),
          ),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (items) => _TransactionGroups(transactions: items),
        );
      },
    );
  }
}

class _TransactionGroups extends StatelessWidget {
  const _TransactionGroups({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const Center(child: Text(AppStrings.noTransactions));
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final key = Formatters.date(DateTime.parse(transaction.date));
      grouped.putIfAbsent(key, () => []).add(transaction);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(date, style: Theme.of(context).textTheme.titleSmall),
            ),
            ...items.map(
              (transaction) => TransactionTile(
                transaction: transaction,
                onTap: () => _openTransaction(context, transaction),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openTransaction(BuildContext context, TransactionModel transaction) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: transaction)),
    );
    if (result == 'saved' && context.mounted) {
      showSuccessSnackBar(context, 'Transaction updated successfully');
    } else if (result == 'deleted' && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
    }
  }
}
