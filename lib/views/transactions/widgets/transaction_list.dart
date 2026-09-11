import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../add_transaction_screen.dart';
import '../transactions_ui_providers.dart';
import 'transaction_tile.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(transactionSearchProvider);
    final categories = ref.watch(selectedCategoryFiltersProvider);

    final transactionsAsync = ref.watch(
      filteredTransactionsProvider(
        type: null,
        search: search,
        categories: categories,
      ),
    );

    return transactionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ShimmerList(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.expenseRed),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            hasFilter: search.isNotEmpty || (categories != null && categories.isNotEmpty),
            onResetFilters: () {
              ref.read(transactionSearchProvider.notifier).state = '';
              clearAllCategoryFilters(ref);
            },
          );
        }

        return _TransactionContent(transactions: items);
      },
    );
  }
}

class _TransactionContent extends StatelessWidget {
  const _TransactionContent({
    required this.transactions,
  });

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    // Group transactions by date string (yyyy-MM-dd)
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction.date));
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    final keys = grouped.keys.toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 110, top: 4),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dateKey = keys[index];
                final dayItems = grouped[dateKey]!;
                final dateObj = DateTime.tryParse(dateKey) ?? DateTime.now();

                return _DaySection(
                  date: dateObj,
                  transactions: dayItems,
                );
              },
              childCount: keys.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({
    required this.date,
    required this.transactions,
  });

  final DateTime date;
  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';

    // Calculate daily net
    double dailyNet = 0;
    for (final t in transactions) {
      dailyNet += t.isIncome ? t.amount : -t.amount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Daily Header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatSmartDate(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (dailyNet >= 0 ? AppColors.incomeGreen : AppColors.expenseRed)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${dailyNet >= 0 ? '+' : ''}${Formatters.currency(dailyNet, symbol: symbol)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dailyNet >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Transactions in this day ─────────────────────────────────
        ...transactions.map(
          (transaction) => TransactionTile(
            transaction: transaction,
            onTap: () => _openTransaction(context, transaction),
            onDelete: () => _deleteTransaction(context, ref, transaction),
          ),
        ),
      ],
    );
  }

  Future<void> _openTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: transaction),
      ),
    );
    if (result == 'saved' && context.mounted) {
      showSuccessSnackBar(context, 'Transaction updated successfully');
    } else if (result == 'deleted' && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    }
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionModel transaction,
  ) async {
    try {
      await ref.read(transactionsProvider.notifier).delete(transaction.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(transactionsProvider.notifier).add(transaction);
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction')),
        );
      }
    }
  }

  static String _formatSmartDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (checkDate == yesterday) {
      return 'Yesterday, ${DateFormat('MMM d').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilter,
    required this.onResetFilters,
  });

  final bool hasFilter;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                size: 38,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilter ? 'No matching transactions' : 'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try changing your search terms or clearing your category filters.'
                  : 'Start tracking your spending and earnings to see your financial activity here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (hasFilter)
              OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset filters'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add transaction'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
