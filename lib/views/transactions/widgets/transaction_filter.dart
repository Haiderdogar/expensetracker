import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/category_provider.dart';

class TransactionFilter extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final usedCatsAsync = ref.watch(usedCategoriesProvider(selectedType));

    return Column(
      children: [
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () async {
                final selected = await showModalBottomSheet<List<String>?>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    final selectedSet = <String>{
                      if (selectedCategories != null) ...selectedCategories!
                    };
                    return StatefulBuilder(
                      builder: (ctx2, setStateSb) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx2).viewInsets.bottom),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Filter by category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx2).pop(null),
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              usedCatsAsync.when(
                                data: (cats) {
                                  if (cats.isEmpty) return const Text('No categories used yet.');
                                  return Wrap(
                                    spacing: 8,
                                    children: cats.map((c) {
                                      final isSelected = selectedSet.contains(c.id);
                                      return ChoiceChip(
                                        label: Text(c.name),
                                        selected: isSelected,
                                        onSelected: (sel) {
                                          setStateSb(() {
                                            if (sel) {
                                              selectedSet.add(c.id);
                                            } else {
                                              selectedSet.remove(c.id);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Text(e.toString()),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(ctx2).pop(null),
                                      child: const Text('Clear'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(ctx2).pop(selectedSet.isEmpty ? null : selectedSet.toList()),
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
                  },
                );
                // selected is List<String>? or null
                onCategorySelected(selected);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selectedType == null,
                onSelected: (_) => onTypeChanged(null),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Income'),
                selected: selectedType == 'income',
                onSelected: (_) => onTypeChanged('income'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Expense'),
                selected: selectedType == 'expense',
                onSelected: (_) => onTypeChanged('expense'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
