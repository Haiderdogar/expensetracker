import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/error_handler.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../transactions/add_transaction_screen.dart';
import '../dashboard_ui_providers.dart';
import 'recent_transaction_tile.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) => const _RecentTransactionsContent();
}

class _RecentTransactionsContent extends StatelessWidget {
  const _RecentTransactionsContent();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final filter = ref.watch(recentTransactionFilterProvider);
        final transactions = ref.watch(transactionsProvider);
        final categories = ref.watch(categoriesProvider).value ?? const <CategoryModel>[];
        final symbol = ref.watch(currencySymbolProvider).value ?? '\$';

        return transactions.when(
          loading: () => const ShimmerList(itemCount: 3, itemHeight: 64),
          error: (error, _) => Text(error.toString()),
          data: (items) {
            final filteredTransactions = filterRecentTransactions(items, filter);
            if (filteredTransactions.isEmpty) {
              return Text(AppStrings.noTransactions, style: Theme.of(context).textTheme.bodyMedium);
            }
            return Column(
              children: filteredTransactions
                  .map(
                    (transaction) => RecentTransactionTile(
                      transaction: transaction,
                      category: _categoryFor(categories, transaction.categoryId),
                      symbol: symbol,
                      onTap: () => _openEditor(context, ref, transaction),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  CategoryModel? _categoryFor(List<CategoryModel> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, TransactionModel transaction) async {
    try {
      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute<dynamic>(builder: (_) => AddTransactionScreen(transaction: transaction)),
      );
      if (result != 'saved' && result != 'created' && result != 'deleted') return;

      await ref.read(transactionsProvider.notifier).refresh();
      if (!context.mounted) return;
      if (result == 'created' || result == 'saved') {
        final message = result == 'created'
            ? 'Transaction added successfully'
            : 'Transaction updated successfully';
        showSuccessSnackBar(context, message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.message(error))),
        );
      }
    }
  }
}

List<TransactionModel> filterRecentTransactions(
  List<TransactionModel> transactions,
  String filter,
) {
  if (filter == 'All') return transactions;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final cutoff = switch (filter) {
    'Today' => today,
    '3 Days' => today.subtract(const Duration(days: 2)),
    '1 Week' => today.subtract(const Duration(days: 6)),
    '1 Month' => today.subtract(const Duration(days: 29)),
    _ => today,
  };
  return transactions.where((transaction) {
    final date = DateTime.tryParse(transaction.date);
    return date != null && !date.isBefore(cutoff);
  }).toList();
}
