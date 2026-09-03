import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../transactions/add_transaction_screen.dart';
import '../../../core/utils/error_handler.dart';

const recentTransactionFilterOptions = <String>[
  'Today',
  '3 Days',
  '1 Week',
  '1 Month',
  'All',
];

final recentTransactionFilterProvider = StateProvider<String>((ref) => 'All');

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(recentTransactionFilterProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final symbolAsync = ref.watch(currencySymbolProvider);

    return transactionsAsync.when(
      loading: () => const ShimmerList(itemCount: 3, itemHeight: 64),
      error: (e, _) => Text(e.toString()),
      data: (transactions) {
        final filteredTransactions = _filterTransactions(
          transactions,
          selectedFilter,
        );
        if (filteredTransactions.isEmpty) {
          return Text(
            AppStrings.noTransactions,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        final categories = categoriesAsync.value ?? [];
        final symbol = symbolAsync.value ?? '\$';

        return Column(
          children: filteredTransactions.map((t) {
            CategoryModel? category;
            for (final item in categories) {
              if (item.id == t.categoryId) {
                category = item;
                break;
              }
            }
            final color = category != null
                ? categoryColorFromHex(category.color)
                : Colors.grey;
            final icon = category != null
                ? categoryIconFromName(category.icon)
                : Icons.receipt;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(t.title),
              subtitle: Text(Formatters.date(DateTime.parse(t.date))),
              trailing: Text(
                '${t.isIncome ? '+' : '-'}${Formatters.currency(t.amount, symbol: symbol)}',
                style: TextStyle(
                  color: t.isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                try {
                  final result = await Navigator.of(context).push<dynamic>(
                    MaterialPageRoute<dynamic>(
                      builder: (_) => AddTransactionScreen(transaction: t),
                    ),
                  );
                  if (result == 'saved' ||
                      result == 'created' ||
                      result == 'deleted') {
                    await ref.read(transactionsProvider.notifier).refresh();
                    if (context.mounted) {
                      final msg = result == 'created'
                          ? 'Transaction added'
                          : (result == 'saved'
                                ? 'Transaction updated'
                                : 'Transaction deleted');
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  }
                } catch (e) {
                  final msg = ErrorHandler.message(e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  }
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  List<TransactionModel> _filterTransactions(
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
}
