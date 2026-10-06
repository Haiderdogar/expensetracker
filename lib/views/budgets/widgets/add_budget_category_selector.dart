import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/category_utils.dart';
import '../../../models/category_model.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/category_provider.dart';
import '../budgets_ui_providers.dart';

class AddBudgetCategorySelector extends ConsumerWidget {
  const AddBudgetCategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(expenseCategoriesProvider);
    final selectedCategory = ref.watch(addBudgetCategoryProvider);
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgetsAsync = ref.watch(monthBudgetProgressProvider(selectedMonth));

    return categories.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Text(error.toString()),
      data: (items) {
        if (items.isEmpty) {
          return const Text('No expense categories available.');
        }

        return budgetsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) => Text('Unable to load existing budgets: $error'),
          data: (budgets) {
            final existingBudgetCategoryIds = budgets
                .map((budget) => budget.budget.categoryId)
                .toSet();
            final activeSelection =
                selectedCategory != null &&
                    !existingBudgetCategoryIds.contains(selectedCategory)
                ? selectedCategory
                : null;

            return _CategoryGrid(
              items: items,
              selectedCategory: activeSelection,
              existingBudgetCategoryIds: existingBudgetCategoryIds,
              budgets: budgets,
              onSelect: (categoryId, hasBudget) {
                ref.read(addBudgetCategoryProvider.notifier).state = hasBudget
                    ? null
                    : categoryId;
              },
            );
          },
        );
      },
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.items,
    required this.selectedCategory,
    required this.existingBudgetCategoryIds,
    required this.budgets,
    required this.onSelect,
  });

  final List<CategoryModel> items;
  final String? selectedCategory;
  final Set<String> existingBudgetCategoryIds;
  final List<BudgetProgress> budgets;
  final void Function(String categoryId, bool hasBudget) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a category',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Select where you want to set a limit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedCategory != null)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 96).floor().clamp(4, 8);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.84,
              ),
              itemBuilder: (context, index) {
                final category = items[index];
                final hasBudget = existingBudgetCategoryIds.contains(
                  category.id,
                );
                final color = categoryColorFromHex(category.color);
                final icon = categoryIconFromName(category.icon);

                return _BudgetCategoryTile(
                  category: category,
                  icon: icon,
                  color: color,
                  isSelected: !hasBudget && selectedCategory == category.id,
                  hasBudget: hasBudget,
                  onTap: () => onSelect(category.id, hasBudget),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  const _BudgetCategoryTile({
    required this.category,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.hasBudget,
    required this.onTap,
  });

  final CategoryModel category;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool hasBudget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.48)
          : hasBudget
          ? colorScheme.surfaceContainerLow.withValues(alpha: 0.55)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: hasBudget ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (isSelected)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surfaceContainerLow,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                category.name,
                maxLines: hasBudget ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: isSelected || hasBudget
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : hasBudget
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
              ),
              if (hasBudget) ...[
                const SizedBox(height: 2),
                Text(
                  'Already set',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    height: 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
