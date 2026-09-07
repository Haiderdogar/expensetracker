import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap, this.onDelete});

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _TransactionCategoryIcon(transaction: transaction),
      title: Text(transaction.subcategory),
      subtitle: _TransactionCategoryLabel(transaction: transaction),
      trailing: _TransactionAmount(transaction: transaction),
    );
  }
}

class _TransactionCategoryIcon extends StatelessWidget {
  const _TransactionCategoryIcon({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final category = _categoryFor(ref.watch(categoriesProvider).value, transaction.categoryId);
        final color = category == null ? AppColors.gray400 : categoryColorFromHex(category.color);
        final icon = category == null ? Icons.receipt : categoryIconFromName(category.icon);
        return CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        );
      },
    );
  }
}

class _TransactionCategoryLabel extends StatelessWidget {
  const _TransactionCategoryLabel({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final category = _categoryFor(ref.watch(categoriesProvider).value, transaction.categoryId);
        return Text('${category?.name ?? 'Unknown'} · ${Formatters.date(DateTime.parse(transaction.date))}');
      },
    );
  }
}

class _TransactionAmount extends StatelessWidget {
  const _TransactionAmount({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
        return Text(
          '${transaction.isIncome ? '+' : '-'}${Formatters.currency(transaction.amount, symbol: symbol)}',
          style: TextStyle(
            color: transaction.isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}

CategoryModel? _categoryFor(List<CategoryModel>? categories, String categoryId) {
  if (categories == null) return null;
  for (final category in categories) {
    if (category.id == categoryId) return category;
  }
  return null;
}
