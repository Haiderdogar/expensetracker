import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/category_utils.dart';
import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import '../transactions_ui_providers.dart';

class TransactionFilter extends StatelessWidget {
  const TransactionFilter({
    super.key,
    required this.selectedType,
    required this.selectedCategories,
    required this.onTypeChanged,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  final String? selectedType;
  final List<String>? selectedCategories;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<List<String>?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: TransactionCategoryFilterButton(
          selectedType: selectedType,
          selectedCategories: selectedCategories,
          onSelected: onCategorySelected,
        ),
      ),
    );
  }
}

class TransactionCategoryFilterButton extends StatelessWidget {
  const TransactionCategoryFilterButton({
    super.key,
    required this.selectedType,
    required this.selectedCategories,
    required this.onSelected,
  });

  final String? selectedType;
  final List<String>? selectedCategories;
  final ValueChanged<List<String>?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showCategoryFilter(context, ref),
        );
      },
    );
  }

  Future<void> _showCategoryFilter(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final allCats = ref.read(categoriesProvider).value ?? const [];

    final availableCats = allCats.where((c) {
      if (selectedType == null) return true;
      return c.type == selectedType;
    }).toList();

    // Filter the initial draft so it only pre-selects categories matching the current section:
    final currentTypeCategoryIds = (selectedCategories ?? []).where((id) {
      if (selectedType == null) return true;
      final cat = allCats.where((c) => c.id == id).firstOrNull;
      return cat?.type == selectedType;
    }).toList();

    ref.read(transactionCategoryFilterDraftProvider.notifier).state =
        currentTypeCategoryIds;

    final selected = await showModalBottomSheet<List<String>?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFilterSheet(
        categories: availableCats,
        selectedType: selectedType,
      ),
    );

    // If dismissed without pressing Apply or Clear, don't change existing selection
    if (selected == null) return;

    if (selectedType == null) {
      onSelected(selected.isEmpty ? null : selected);
    } else {
      // In Income or Expense section, preserve the other type's categories
      final otherTypeCategoryIds = (selectedCategories ?? []).where((id) {
        final cat = allCats.where((c) => c.id == id).firstOrNull;
        return cat != null && cat.type != selectedType;
      }).toList();

      final combined = [
        ...otherTypeCategoryIds,
        ...selected,
      ];
      onSelected(combined.isEmpty ? null : combined);
    }
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({
    required this.categories,
    required this.selectedType,
  });

  final List<CategoryModel> categories;
  final String? selectedType;

  @override
  Widget build(BuildContext context) {
    final title = selectedType == 'income'
        ? 'Filter by income categories'
        : selectedType == 'expense'
            ? 'Filter by expense categories'
            : 'Filter by categories';

    return Consumer(
      builder: (context, ref, _) {
        final selected =
            ref.watch(transactionCategoryFilterDraftProvider).toSet();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(<String>[]),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No categories available.'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map<Widget>((category) {
                    final isSelected = selected.contains(category.id);
                    final chipColor =
                        category.isIncome ? Colors.green : Colors.red;
                    return FilterChip(
                      avatar: Icon(
                        categoryIconFromName(category.icon),
                        size: 14,
                        color: isSelected ? Colors.white : chipColor,
                      ),
                      label: Text(category.name),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: chipColor,
                      backgroundColor: chipColor.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: isSelected
                            ? chipColor
                            : chipColor.withValues(alpha: 0.3),
                        width: isSelected ? 1.5 : 1,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : chipColor,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (value) {
                        final updated = {...selected};
                        value
                            ? updated.add(category.id)
                            : updated.remove(category.id);
                        ref
                            .read(transactionCategoryFilterDraftProvider.notifier)
                            .state = updated.toList();
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(<String>[]),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(selected.toList()),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
