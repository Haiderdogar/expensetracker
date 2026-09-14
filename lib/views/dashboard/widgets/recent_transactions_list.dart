import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../transactions/add_transaction_screen.dart';
import '../dashboard_ui_providers.dart';
import 'recent_transaction_tile.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(recentTransactionFilterProvider);
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider).value ?? const <CategoryModel>[];
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final selectedWalletId = ref.watch(selectedWalletIdProvider);

    return transactions.when(
      loading: () => const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ShimmerList(itemCount: 4, itemHeight: 64),
        ),
      ),
      error: (error, _) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: Text(
              ErrorHandler.message(error),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
      data: (items) {
        final filteredByWallet = selectedWalletId == null
            ? items
            : items.where((t) => t.walletId == selectedWalletId).toList();
        final filteredTransactions = filterRecentTransactions(filteredByWallet, filter);

        if (filteredTransactions.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildEmptyState(context),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: filteredTransactions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return RecentTransactionTile(
                transaction: transaction,
                category: _categoryFor(categories, transaction.categoryId),
                symbol: symbol,
                onTap: () => _openEditor(context, ref, transaction),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.noTransactions,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transactions you record will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push<dynamic>(
              MaterialPageRoute<dynamic>(
                builder: (_) => const AddTransactionScreen(),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Transaction'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CategoryModel? _categoryFor(List<CategoryModel> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, TransactionModel transaction) async {
    if (transaction.type == 'transfer') {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('Transfer Details'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.subcategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Amount: ${Formatters.currency(transaction.amount)}'),
              const SizedBox(height: 4),
              Text('Date: ${Formatters.date(DateTime.parse(transaction.date))}'),
              if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Note: ${transaction.note}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

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
        showSuccessSnackBar(context, 'Transaction deleted');
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
