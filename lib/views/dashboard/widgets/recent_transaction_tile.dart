import 'package:flutter/material.dart';

import '../../../core/utils/category_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';

class RecentTransactionTile extends StatelessWidget {
  const RecentTransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.symbol,
    required this.onTap,
  });

  final TransactionModel transaction;
  final CategoryModel? category;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.type == 'transfer';
    final color = isTransfer
        ? Colors.blue
        : (category == null ? Colors.grey : categoryColorFromHex(category!.color));
    final icon = isTransfer
        ? Icons.swap_horiz_rounded
        : (category == null ? Icons.receipt : categoryIconFromName(category!.icon));
    final prefix = isTransfer ? '⇄ ' : (transaction.isIncome ? '+' : '-');
    final amountColor = isTransfer
        ? Colors.blue
        : (transaction.isIncome ? Colors.green : Colors.red);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(transaction.title),
      subtitle: Text(Formatters.date(DateTime.parse(transaction.date))),
      trailing: Text(
        '$prefix${Formatters.currency(transaction.amount, symbol: symbol)}',
        style: TextStyle(
          color: amountColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
