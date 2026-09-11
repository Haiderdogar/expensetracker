import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import '../transactions_ui_providers.dart';

class TransactionFilter extends ConsumerStatefulWidget {
  const TransactionFilter({
    super.key,
    required this.selectedCategories,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  final List<String>? selectedCategories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<List<String>?> onCategorySelected;

  @override
  ConsumerState<TransactionFilter> createState() => _TransactionFilterState();
}

class _TransactionFilterState extends ConsumerState<TransactionFilter> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(transactionSearchProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(transactionSearchProvider, (_, next) {
      if (_controller.text != next) {
        _controller.text = next;
      }
    });

    final scheme = Theme.of(context).colorScheme;
    final hasSearch = _controller.text.isNotEmpty;
    final activeFilterCount = widget.selectedCategories?.length ?? 0;
    final hasActiveFilters = activeFilterCount > 0;

    return Row(
      children: [
        // ── Search Input ────────────────────────────────────────────────
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (val) {
              setState(() {});
              widget.onSearchChanged(val);
            },
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
              suffixIcon: hasSearch
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: scheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ── Single Visual Filter Button ─────────────────────────────────
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showUnifiedCategoryFilterSheet(
              context: context,
              ref: ref,
              selectedCategories: widget.selectedCategories,
              onSelected: widget.onCategorySelected,
            ),
            child: Ink(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: hasActiveFilters
                    ? scheme.primary.withValues(alpha: 0.12)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasActiveFilters
                      ? scheme.primary.withValues(alpha: 0.45)
                      : scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: hasActiveFilters
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasActiveFilters
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showUnifiedCategoryFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<String>? selectedCategories,
  required ValueChanged<List<String>?> onSelected,
}) async {
  final allCats = ref.read(categoriesProvider).value ?? const [];

  final selected = await showModalBottomSheet<List<String>?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _UnifiedCategoryFilterSheet(
      allCategories: allCats,
      initialSelected: selectedCategories,
    ),
  );

  if (selected == null) return;
  onSelected(selected.isEmpty ? null : selected);
}

class _UnifiedCategoryFilterSheet extends StatefulWidget {
  const _UnifiedCategoryFilterSheet({
    required this.allCategories,
    required this.initialSelected,
  });

  final List<CategoryModel> allCategories;
  final List<String>? initialSelected;

  @override
  State<_UnifiedCategoryFilterSheet> createState() =>
      _UnifiedCategoryFilterSheetState();
}

class _UnifiedCategoryFilterSheetState
    extends State<_UnifiedCategoryFilterSheet> {
  late final Set<String> _draftSelected;

  @override
  void initState() {
    super.initState();
    _draftSelected = Set<String>.from(widget.initialSelected ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expenseCategories =
        widget.allCategories.where((c) => c.type == 'expense').toList();
    final incomeCategories =
        widget.allCategories.where((c) => c.type == 'income').toList();

    final isAllExpenseSelected = expenseCategories.isNotEmpty &&
        expenseCategories.every((c) => _draftSelected.contains(c.id));
    final isAllIncomeSelected = incomeCategories.isNotEmpty &&
        incomeCategories.every((c) => _draftSelected.contains(c.id));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle / Drag indicator ────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header Title ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Scrollable Sections (Expense & Income) ─────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Expense Section ───────────────────────────────────────
                  _buildSectionHeader(
                    title: 'Expense',
                    color: AppColors.expenseRed,
                    isAllSelected: isAllExpenseSelected,
                    onToggleSelectAll: () {
                      setState(() {
                        if (isAllExpenseSelected) {
                          _draftSelected
                              .removeAll(expenseCategories.map((c) => c.id));
                        } else {
                          _draftSelected
                              .addAll(expenseCategories.map((c) => c.id));
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (expenseCategories.isEmpty)
                    const Text('No expense categories available.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expenseCategories.map((cat) {
                        final isSelected = _draftSelected.contains(cat.id);
                        return FilterChip(
                          avatar: Icon(
                            categoryIconFromName(cat.icon),
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : AppColors.expenseRed,
                          ),
                          label: Text(cat.name),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: AppColors.expenseRed,
                          backgroundColor:
                              AppColors.expenseRed.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.expenseRed
                                : AppColors.expenseRed.withValues(alpha: 0.3),
                            width: isSelected ? 1.5 : 1,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.expenseRed,
                          ),
                          visualDensity: VisualDensity.compact,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _draftSelected.add(cat.id);
                              } else {
                                _draftSelected.remove(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // ── Income Section ────────────────────────────────────────
                  _buildSectionHeader(
                    title: 'Income',
                    color: AppColors.incomeGreen,
                    isAllSelected: isAllIncomeSelected,
                    onToggleSelectAll: () {
                      setState(() {
                        if (isAllIncomeSelected) {
                          _draftSelected
                              .removeAll(incomeCategories.map((c) => c.id));
                        } else {
                          _draftSelected
                              .addAll(incomeCategories.map((c) => c.id));
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (incomeCategories.isEmpty)
                    const Text('No income categories available.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: incomeCategories.map((cat) {
                        final isSelected = _draftSelected.contains(cat.id);
                        return FilterChip(
                          avatar: Icon(
                            categoryIconFromName(cat.icon),
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : AppColors.incomeGreen,
                          ),
                          label: Text(cat.name),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: AppColors.incomeGreen,
                          backgroundColor:
                              AppColors.incomeGreen.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.incomeGreen
                                : AppColors.incomeGreen.withValues(alpha: 0.3),
                            width: isSelected ? 1.5 : 1,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.incomeGreen,
                          ),
                          visualDensity: VisualDensity.compact,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _draftSelected.add(cat.id);
                              } else {
                                _draftSelected.remove(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom Action Bar (Clear & Apply) ───────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _draftSelected.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(_draftSelected.toList());
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Color color,
    required bool isAllSelected,
    required VoidCallback onToggleSelectAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: onToggleSelectAll,
          icon: Icon(
            isAllSelected
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: isAllSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: Text(
            isAllSelected ? 'Deselect All' : 'Select All',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isAllSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
