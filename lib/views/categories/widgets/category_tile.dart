import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import 'category_management_dialogs.dart';

class CategoryTile extends ConsumerWidget {
  const CategoryTile({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color(category.color);
    final colorScheme = Theme.of(context).colorScheme;
    final status = category.isHidden
        ? 'Hidden'
        : category.isArchived
        ? 'Archived'
        : category.isBuiltIn
        ? 'Built-in'
        : 'Custom';
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIconFromName(category.icon),
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 19,
                    tooltip: 'Category actions',
                    onSelected: (action) =>
                        _categoryAction(context, ref, action),
                    itemBuilder: (_) => category.isBuiltIn
                        ? [
                            PopupMenuItem(
                              value: category.isHidden ? 'unhide' : 'hide',
                              child: Text(
                                category.isHidden
                                    ? 'Show category'
                                    : 'Hide category',
                              ),
                            ),
                          ]
                        : [
                            if (category.isArchived)
                              const PopupMenuItem(
                                value: 'restore',
                                child: Text('Restore'),
                              )
                            else
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: category.isHidden || category.isArchived
                        ? colorScheme.onSurfaceVariant
                        : color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (category.isBuiltIn)
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
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
