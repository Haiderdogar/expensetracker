import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import 'category_management_dialogs.dart';

class CategoryTile extends ConsumerWidget {
  const CategoryTile({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color(category.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .16),
          child: Icon(_icon(category.icon), color: color),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(category.isIncome ? 'Income' : 'Expense'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _categoryAction(context, ref, action),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _categoryAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'edit') {
      final name = await showNameDialog(
        context,
        'Edit category',
        initialName: category.name,
      );
      if (name == null || !context.mounted) return;
      try {
        await ref
            .read(categoriesProvider.notifier)
            .updateCategory(category.copyWith(name: name));
        if (context.mounted) {
          showSuccessSnackBar(context, 'Category updated successfully');
        }
      } catch (error) {
        if (context.mounted) showError(context, error);
      }
      return;
    }
    final ok = await confirmDelete(
      context,
      'Delete ${category.name}?',
      'Transactions and budgets using this category cannot be deleted.',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(categoriesProvider.notifier).delete(category.id);
      if (context.mounted) {
        showSuccessSnackBar(context, 'Category deleted successfully');
      }
    } catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

}

Color _color(String value) => Color(
  0xFF000000 |
      (int.tryParse(value.replaceFirst('#', ''), radix: 16) ?? 0x2563EB),
);

IconData _icon(String icon) => switch (icon) {
  'work' => Icons.work_outline_rounded,
  'laptop' => Icons.laptop_mac_rounded,
  'trending_up' => Icons.trending_up_rounded,
  'home' => Icons.home_outlined,
  'store' => Icons.storefront_outlined,
  'restaurant' => Icons.restaurant_rounded,
  'directions_car' => Icons.directions_car_rounded,
  'shopping_bag' => Icons.shopping_bag_outlined,
  'receipt' => Icons.receipt_long_outlined,
  'movie' => Icons.movie_outlined,
  'favorite' => Icons.favorite_outline_rounded,
  'school' => Icons.school_outlined,
  'shield' => Icons.shield_outlined,
  'flight' => Icons.flight_outlined,
  'spa' => Icons.spa_outlined,
  _ => Icons.category_outlined,
};
