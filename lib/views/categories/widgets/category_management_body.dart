import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/category_utils.dart';
import '../../../core/utils/error_handler.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import 'category_section.dart';

class CategoryManagementBody extends ConsumerWidget {
  const CategoryManagementBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider).value ?? const [];
    if (categories.isLoading && !categories.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (categories.hasError && !categories.hasValue) {
      return Center(child: Text(ErrorHandler.message(categories.error!)));
    }
    final items = categories.value ?? [];
        final incomeCategories = sortCategories(
          items.where((item) => item.isIncome).toList(),
          transactions,
        );
        final expenseCategories = sortCategories(
          items.where((item) => item.isExpense).toList(),
          transactions,
        );
        final visibleCount = items
            .where((item) => !item.isHidden && !item.isArchived)
            .length;
        final customCount = items.where((item) => !item.isBuiltIn).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
          children: [
            _Header(
              total: visibleCount,
              incomeCount: incomeCategories
                  .where((item) => !item.isHidden && !item.isArchived)
                  .length,
              expenseCount: expenseCategories
                  .where((item) => !item.isHidden && !item.isArchived)
                  .length,
              customCount: customCount,
            ),
            const SizedBox(height: 22),
            CategorySection(
              title: 'Income',
              subtitle: 'Money coming in',
              icon: Icons.south_west_rounded,
              accent: const Color(0xFF10B981),
              categories: incomeCategories,
            ),
            const SizedBox(height: 16),
            CategorySection(
              title: 'Expenses',
              subtitle: 'Money going out',
              icon: Icons.north_east_rounded,
              accent: const Color(0xFFF97316),
              categories: expenseCategories,
            ),
          ],
        );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.incomeCount,
    required this.expenseCount,
    required this.customCount,
  });

  final int total;
  final int incomeCount;
  final int expenseCount;
  final int customCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.tertiary, 0.55)!,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total active ${total == 1 ? 'category' : 'categories'}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Keep every transaction organized.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'INCOME',
                  count: incomeCount,
                  icon: Icons.south_west_rounded,
                ),
              ),
              _summaryDivider(),
              Expanded(
                child: _SummaryValue(
                  label: 'EXPENSE',
                  count: expenseCount,
                  icon: Icons.north_east_rounded,
                ),
              ),
              _summaryDivider(),
              Expanded(
                child: _SummaryValue(
                  label: 'CUSTOM',
                  count: customCount,
                  icon: Icons.tune_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() => Container(
    width: 1,
    height: 38,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withValues(alpha: 0.22),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.65,
              fontSize: 9,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '$count',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
