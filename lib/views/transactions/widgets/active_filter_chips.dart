import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/category_utils.dart';
import '../../../providers/category_provider.dart';
import '../transactions_ui_providers.dart';

/// Always-visible filter bar on the transactions screen.
/// - Top row: All / Income / Expense section toggles.
/// - Bottom row: Horizontally scrollable multi-select category filter chips
///   corresponding to the active section (all categories in 'All', multiple expense
///   categories in 'Expense', multiple income categories in 'Income').
/// - When filters of the current section are active, a 'Clear' chip appears to quickly reset them.
class ActiveFilterChips extends ConsumerWidget {
  const ActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(transactionTypeFilterProvider);
    final selectedCategories = ref.watch(transactionCategoryFilterProvider);
    final allCategories = ref.watch(categoriesProvider).value ?? const [];

    // Categories relevant to the current section:
    // - 'All' (type == null): all categories
    // - 'Income' (type == 'income'): only income categories
    // - 'Expense' (type == 'expense'): only expense categories
    final sectionCategories = allCategories.where((c) {
      if (type == null) return true;
      return c.type == type;
    }).toList();

    // Selected category IDs that belong to the current section:
    final selectedInCurrentSection = (selectedCategories ?? []).where((id) {
      if (type == null) return true;
      final cat = allCategories.where((c) => c.id == id).firstOrNull;
      return cat?.type == type;
    }).toList();

    final hasActiveFilters = selectedInCurrentSection.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: Section toggles (All / Income / Expense) ───────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _TypeChip(
                label: 'All',
                selected: type == null,
                color: scheme.primary,
                onTap: () =>
                    ref.read(transactionTypeFilterProvider.notifier).state = null,
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Income',
                selected: type == 'income',
                color: Colors.green,
                onTap: () => ref
                    .read(transactionTypeFilterProvider.notifier)
                    .state = type == 'income' ? null : 'income',
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Expense',
                selected: type == 'expense',
                color: Colors.red,
                onTap: () => ref
                    .read(transactionTypeFilterProvider.notifier)
                    .state = type == 'expense' ? null : 'expense',
              ),
            ],
          ),
        ),

        // ── Row 2: Multi-select category chips for the active section ──────
        if (sectionCategories.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  (hasActiveFilters ? 1 : 0) + sectionCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // Clear chip when any category filter in this section is active
                if (hasActiveFilters && index == 0) {
                  return ActionChip(
                    avatar: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: scheme.error,
                    ),
                    label: Text(
                      'Clear (${selectedInCurrentSection.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.error,
                      ),
                    ),
                    backgroundColor: scheme.error.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.35),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      final toRemove = selectedInCurrentSection.toSet();
                      final updated = (selectedCategories ?? [])
                          .where((id) => !toRemove.contains(id))
                          .toList();
                      ref
                          .read(transactionCategoryFilterProvider.notifier)
                          .state = updated.isEmpty ? null : updated;
                    },
                  );
                }

                final catIndex = hasActiveFilters ? index - 1 : index;
                final category = sectionCategories[catIndex];
                final isSelected =
                    selectedInCurrentSection.contains(category.id);
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
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onSelected: (selected) {
                    final current = selectedCategories ?? [];
                    final updated = selected
                        ? [...current, category.id]
                        : current.where((id) => id != category.id).toList();
                    ref
                        .read(transactionCategoryFilterProvider.notifier)
                        .state = updated.isEmpty ? null : updated;
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Type filter chip (selectable toggle) ──────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: color.withValues(alpha: 0.18),
        side: BorderSide(
          color: selected
              ? color
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? color
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
