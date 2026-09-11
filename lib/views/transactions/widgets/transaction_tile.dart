import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../models/wallet_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/wallet_provider.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final wallets = ref.watch(walletsProvider).value ?? const [];
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';

    final category = _categoryFor(categories, transaction.categoryId);
    final wallet = _walletFor(wallets, transaction.walletId);

    final color = category == null
        ? AppColors.gray400
        : categoryColorFromHex(category.color);
    final icon = category == null
        ? Icons.receipt_rounded
        : categoryIconFromName(category.icon);

    final dateTime = DateTime.tryParse(transaction.date);
    final timeStr = dateTime != null ? DateFormat.jm().format(dateTime) : '';

    final tileContent = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Category Icon Squircle ─────────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 22),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Subcategory / Category / Wallet info ───────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.subcategory.isNotEmpty
                            ? transaction.subcategory
                            : (category?.name ?? 'Transaction'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (category != null &&
                              transaction.subcategory.isNotEmpty &&
                              transaction.subcategory != category.name) ...[
                            Flexible(
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (wallet != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 10,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    wallet.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (transaction.note?.trim().isNotEmpty == true) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.notes_rounded,
                              size: 13,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── Amount & Time ──────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${transaction.isIncome ? '+' : '-'}${Formatters.currency(transaction.amount, symbol: symbol)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: transaction.isIncome
                            ? AppColors.incomeGreen
                            : AppColors.expenseRed,
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: Key('tx_${transaction.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete transaction?'),
              content: Text(
                'Are you sure you want to delete this ${transaction.isIncome ? 'income' : 'expense'} transaction of ${Formatters.currency(transaction.amount, symbol: symbol)}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.expenseRed),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            onDelete!();
            return true;
          }
          return false;
        },
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.expenseRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.expenseRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        child: tileContent,
      );
    }

    return tileContent;
  }
}

CategoryModel? _categoryFor(
    List<CategoryModel>? categories, String categoryId) {
  if (categories == null) return null;
  for (final category in categories) {
    if (category.id == categoryId) return category;
  }
  return null;
}

WalletModel? _walletFor(List<WalletModel>? wallets, String walletId) {
  if (wallets == null) return null;
  for (final wallet in wallets) {
    if (wallet.id == walletId) return wallet;
  }
  return null;
}
