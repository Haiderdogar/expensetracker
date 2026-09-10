import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/category_utils.dart';
import '../../../core/utils/error_handler.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import 'category_section.dart';

class CategoryManagementBody extends StatelessWidget {
  const CategoryManagementBody({super.key});

  @override
  Widget build(BuildContext context) => Consumer(
        builder: (context, ref, _) {
          final categories = ref.watch(categoriesProvider);
          final transactions = ref.watch(transactionsProvider).value ?? const [];
          return categories.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(ErrorHandler.message(error))),
            data: (items) {
              final incomeCategories = sortCategories(
                items.where((item) => item.isIncome).toList(),
                transactions,
              );
              final expenseCategories = sortCategories(
                items.where((item) => item.isExpense).toList(),
                transactions,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  _Header(total: items.length),
                  const SizedBox(height: 24),
                  CategorySection(title: 'Income', categories: incomeCategories),
                  const SizedBox(height: 24),
                  CategorySection(title: 'Expenses', categories: expenseCategories),
                ],
              );
            },
          );
        },
      );
}


class _Header extends StatelessWidget {
  const _Header({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.secondary]), borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        const CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(Icons.category_rounded, color: Colors.white)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$total categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          Text('Organise every transaction.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ]),
      ]),
    );
  }
}
