import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../transactions/add_transaction_screen.dart';
import '../../../core/utils/error_handler.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final symbolAsync = ref.watch(currencySymbolProvider);

    return recentAsync.when(
      loading: () => const ShimmerList(itemCount: 3, itemHeight: 64),
      error: (e, _) => Text(e.toString()),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Text(
            AppStrings.noTransactions,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        final categories = categoriesAsync.value ?? [];
        final symbol = symbolAsync.value ?? '\$';

        return Column(
          children: transactions.map((t) {
            final category = categories.cast<CategoryModel?>().firstWhere(
                  (c) => c!.id == t.categoryId,
                  orElse: () => null,
                );
            final color = category != null
                ? categoryColorFromHex(category.color)
                : Colors.grey;
            final icon = category != null
                ? categoryIconFromName(category.icon)
                : Icons.receipt;

            return Dismissible(
              key: ValueKey(t.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Delete transaction'),
                    content: const Text('Delete this transaction? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Delete')),
                    ],
                  ),
                );
                return confirm == true;
              },
              onDismissed: (_) async {
                try {
                  await ref.read(transactionsProvider.notifier).delete(t.id);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                } catch (e) {
                  final msg = ErrorHandler.message(e);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
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
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(builder: (_) => AddTransactionScreen(transaction: t)),
                    );
                    if (result == true) {
                      await ref.read(transactionsProvider.notifier).refresh();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction updated')));
                    }
                  } catch (e) {
                    final msg = ErrorHandler.message(e);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
