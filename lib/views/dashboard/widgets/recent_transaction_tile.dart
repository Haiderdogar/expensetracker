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
    final color = category == null ? Colors.grey : categoryColorFromHex(category!.color);
    final icon = category == null ? Icons.receipt : categoryIconFromName(category!.icon);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(transaction.subcategory),
      subtitle: Text(Formatters.date(DateTime.parse(transaction.date))),
      trailing: Text(
        '${transaction.isIncome ? '+' : '-'}${Formatters.currency(transaction.amount, symbol: symbol)}',
        style: TextStyle(
          color: transaction.isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
