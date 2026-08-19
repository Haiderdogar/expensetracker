import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';

    final category = categories.cast<CategoryModel?>().firstWhere(
          (c) => c!.id == transaction.categoryId,
          orElse: () => null,
        );
    final color = category != null
        ? categoryColorFromHex(category.color)
        : AppColors.gray400;
    final icon = category != null
        ? categoryIconFromName(category.icon)
        : Icons.receipt;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      // Ask for confirmation before dismissing
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
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.expenseRed,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(transaction.title),
        subtitle: Text(
          '${category?.name ?? 'Unknown'} · ${Formatters.date(DateTime.parse(transaction.date))}',
        ),
        trailing: Text(
          '${transaction.isIncome ? '+' : '-'}${Formatters.currency(transaction.amount, symbol: symbol)}',
          style: TextStyle(
            color: transaction.isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
