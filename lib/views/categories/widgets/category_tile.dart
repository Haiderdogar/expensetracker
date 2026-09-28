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
        subtitle: Text(
          category.isBuiltIn
              ? category.isHidden
                    ? 'Built-in · Hidden on this device'
                    : 'Built-in · Shared across wallets'
              : category.isArchived
              ? 'Custom · Archived'
              : category.isIncome
              ? 'Custom · Income'
              : 'Custom · Expense',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _categoryAction(context, ref, action),
          itemBuilder: (_) => category.isBuiltIn
              ? [
                  PopupMenuItem(
                    value: category.isHidden ? 'unhide' : 'hide',
                    child: Text(category.isHidden ? 'Show category' : 'Hide on this device'),
                  ),
                ]
              : [
                  if (category.isArchived)
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('Restore'),
                    )
                  else
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    if (action == 'hide' || action == 'unhide') {
      try {
        await ref
            .read(categoriesProvider.notifier)
            .setBuiltInHidden(category.id, hidden: action == 'hide');
        if (context.mounted) {
          showSuccessSnackBar(
            context,
            action == 'hide'
                ? 'Category hidden on this device'
                : 'Category shown on this device',
          );
        }
      } catch (error) {
        if (context.mounted) showError(context, error);
      }
      return;
    }
    if (action == 'restore') {
      try {
        await ref
            .read(categoriesProvider.notifier)
            .updateCategory(category.copyWith(isArchived: false));
        if (context.mounted) {
          showSuccessSnackBar(context, 'Category restored successfully');
        }
      } catch (error) {
        if (context.mounted) showError(context, error);
      }
      return;
    }
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
      'This will not delete any transactions or budgets. If this category is in use, it will be archived so it remains visible in your history.',
    );
    if (!ok || !context.mounted) return;
    try {
      final wasArchived = await ref
          .read(categoriesProvider.notifier)
          .delete(category.id);
      if (context.mounted) {
        showSuccessSnackBar(
          context,
          wasArchived
              ? 'Category archived; transaction history is preserved'
              : 'Category deleted successfully',
        );
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
