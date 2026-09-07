import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/category_provider.dart';
import '../transactions_ui_providers.dart';

class TransactionFilter extends StatelessWidget {
  const TransactionFilter({super.key, required this.selectedType, required this.selectedCategories, required this.onTypeChanged, required this.onSearchChanged, required this.onCategorySelected});

  final String? selectedType;
  final List<String>? selectedCategories;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<List<String>?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
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
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(label: const Text('All'), selected: selectedType == null, onSelected: (_) => onTypeChanged(null)),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Income'), selected: selectedType == 'income', onSelected: (_) => onTypeChanged('income')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Expense'), selected: selectedType == 'expense', onSelected: (_) => onTypeChanged('expense')),
            ],
          ),
        ),
      ],
    );
  }
}

class TransactionCategoryFilterButton extends StatelessWidget {
  const TransactionCategoryFilterButton({super.key, required this.selectedType, required this.selectedCategories, required this.onSelected});

  final String? selectedType;
  final List<String>? selectedCategories;
  final ValueChanged<List<String>?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final categories = ref.watch(usedCategoriesProvider(selectedType));
        return IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showCategoryFilter(context, ref, categories),
        );
      },
    );
  }

  Future<void> _showCategoryFilter(BuildContext context, WidgetRef ref, AsyncValue<dynamic> categories) async {
    ref.read(transactionCategoryFilterDraftProvider.notifier).state = [...?selectedCategories];
    final selected = await showModalBottomSheet<List<String>?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFilterSheet(categories: categories),
    );
    onSelected(selected);
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({required this.categories});

  final AsyncValue<dynamic> categories;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(transactionCategoryFilterDraftProvider).toSet();
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter by category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Clear')),
                ],
              ),
              const SizedBox(height: 8),
              categories.when(
                data: (items) => items.isEmpty
                    ? const Text('No categories used yet.')
                    : Wrap(
                        spacing: 8,
                        children: items.map<Widget>((category) {
                          final isSelected = selected.contains(category.id);
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (value) {
                              final updated = {...selected};
                              value ? updated.add(category.id) : updated.remove(category.id);
                              ref.read(transactionCategoryFilterDraftProvider.notifier).state = updated.toList();
                            },
                          );
                        }).toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(error.toString()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Clear'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.of(context).pop(selected.isEmpty ? null : selected.toList()), child: const Text('Apply'))),
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
