import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import '../transactions_ui_providers.dart';

/// Renders applied category filter badges directly below the Search/Filter bar,
/// separated independently into Expense Active Filters and Income Active Filters.
class ActiveFilterChips extends ConsumerWidget {
  const ActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategories = ref.watch(selectedCategoryFiltersProvider);
    final allCategories = ref.watch(categoriesProvider).value ?? const [];

    if (selectedCategories == null || selectedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final expenseCategories = allCategories
        .where((c) => c.type == 'expense')
        .toList();
    final incomeCategories = allCategories
        .where((c) => c.type == 'income')
        .toList();

    final selectedExpenseCats = expenseCategories
        .where((c) => selectedCategories.contains(c.id))
        .toList();
    final selectedIncomeCats = incomeCategories
        .where((c) => selectedCategories.contains(c.id))
        .toList();

    final hasExpenseFilters = selectedExpenseCats.isNotEmpty;
    final hasIncomeFilters = selectedIncomeCats.isNotEmpty;

    if (!hasExpenseFilters && !hasIncomeFilters) {
      return const SizedBox.shrink();
    }

    final isAllExpenseSelected =
        expenseCategories.isNotEmpty &&
        selectedExpenseCats.length == expenseCategories.length;
    final isAllIncomeSelected =
        incomeCategories.isNotEmpty &&
        selectedIncomeCats.length == incomeCategories.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Expense Active Filters ───────────────────────────────────────
          if (hasExpenseFilters) ...[
            _FilterBadgeRow(
              isAllSelected: isAllExpenseSelected,
              allSelectedLabel: 'All Expense Filters Applied',
              clearAllLabel: 'Clear All Expense',
              color: AppColors.expenseRed,
              selectedCats: selectedExpenseCats,
              onClearAll: () =>
                  clearCategoryFiltersByType(ref, 'expense', allCategories),
              onRemoveCat: (catId) => removeCategoryFilter(ref, catId),
            ),
          ],

          if (hasExpenseFilters && hasIncomeFilters) const SizedBox(height: 6),

          // ── Income Active Filters ────────────────────────────────────────
          if (hasIncomeFilters) ...[
            _FilterBadgeRow(
              isAllSelected: isAllIncomeSelected,
              allSelectedLabel: 'All Income Filters Applied',
              clearAllLabel: 'Clear All Income',
              color: AppColors.incomeGreen,
              selectedCats: selectedIncomeCats,
              onClearAll: () =>
                  clearCategoryFiltersByType(ref, 'income', allCategories),
              onRemoveCat: (catId) => removeCategoryFilter(ref, catId),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterBadgeRow extends StatelessWidget {
  const _FilterBadgeRow({
    required this.isAllSelected,
    required this.allSelectedLabel,
    required this.clearAllLabel,
    required this.color,
    required this.selectedCats,
    required this.onClearAll,
    required this.onRemoveCat,
  });

  final bool isAllSelected;
  final String allSelectedLabel;
  final String clearAllLabel;
  final Color color;
  final List<CategoryModel> selectedCats;
  final VoidCallback onClearAll;
  final ValueChanged<String> onRemoveCat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // ── Case 1: "Select All" active for a type ───────────────────────────
    if (isAllSelected) {
      return SizedBox(
        height: 30,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            InputChip(
              avatar: Icon(Icons.done_all_rounded, size: 13, color: color),
              label: Text(allSelectedLabel),
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
              deleteIconColor: color,
              onDeleted: onClearAll,
              onPressed: onClearAll,
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              labelPadding: const EdgeInsets.only(left: 2, right: 0),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(left: 4, right: 2),
            ),
          ],
        ),
      );
    }

    // ── Case 2: Partial or specific selection ────────────────────────────
    final showClearAll = selectedCats.length > 1;

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: selectedCats.length + (showClearAll ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          // Show "Clear All [Type]" badge at the START when more than one category is selected
          if (showClearAll && index == 0) {
            return InputChip(
              label: Text(clearAllLabel),
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
              deleteIconColor: scheme.error,
              onDeleted: onClearAll,
              onPressed: onClearAll,
              backgroundColor: scheme.error.withValues(alpha: 0.08),
              side: BorderSide(color: scheme.error.withValues(alpha: 0.35)),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
              labelPadding: const EdgeInsets.only(left: 4, right: 0),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(left: 4, right: 2),
            );
          }

          final catIndex = showClearAll ? index - 1 : index;
          final category = selectedCats[catIndex];
          return InputChip(
            avatar: Icon(
              categoryIconFromName(category.icon),
              size: 13,
              color: color,
            ),
            label: Text(category.name),
            deleteIcon: const Icon(Icons.close_rounded, size: 16),
            deleteIconColor: color,
            onDeleted: () => onRemoveCat(category.id),
            onPressed: () => onRemoveCat(category.id),
            backgroundColor: color.withValues(alpha: 0.08),
            side: BorderSide(color: color.withValues(alpha: 0.35)),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            labelPadding: const EdgeInsets.only(left: 2, right: 0),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.only(left: 4, right: 2),
          );
        },
      ),
    );
  }
}
