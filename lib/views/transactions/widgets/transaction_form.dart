import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../features/wallet_currency/providers/wallet_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../transactions_ui_providers.dart';

class TransactionForm extends ConsumerWidget {
  TransactionForm({super.key, this.transaction});

  final TransactionModel? transaction;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(transactionFormProvider(transaction));
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // Only allow switching type when creating a new transaction.
          // When editing, the type is locked to the original transaction type.
          if (transaction == null) ...[
            _TypeSelector(
              draft: draft,
              onChanged: (type) => _changeType(ref, draft, type),
            ),
            const SizedBox(height: 5),
          ],
          _CategorySelector(transaction: transaction, draft: draft),
          const SizedBox(height: 8),
          _TitleField(transaction: transaction, draft: draft),
          const SizedBox(height: 5),
          // Key on amount ensures the field rebuilds with the correct
          // per-tab initialValue whenever the user switches expense/income.
          CustomTextField(
            key: ValueKey('amount_${draft.type}'),
            initialValue: draft.amount,
            label: AppStrings.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(ref.watch(currencySymbolProvider).value ?? '\$'),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (double.tryParse(value) == null) return 'Invalid amount';
              return null;
            },
            onChanged: (value) =>
                _updateDraft(ref, draft.copyWith(amount: value)),
          ),
          CustomTextField(
            initialValue: draft.note,
            label: AppStrings.note,
            hint: draft.type == 'income'
                ? 'Add details of your income'
                : 'Add details of your expense',
            maxLines: 3,
            onChanged: (value) =>
                _updateDraft(ref, draft.copyWith(note: value)),
          ),
//          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${AppStrings.date} & Time'),
            subtitle: Text(Formatters.dateTime(draft.date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDateTime(context, ref, draft),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: AppStrings.save,
            isLoading: draft.isSaving,
            onPressed: () => _save(context, ref, draft),
          ),
        ],
      ),
    );
  }

  void _updateDraft(WidgetRef ref, TransactionFormDraft draft) {
    ref.read(transactionFormProvider(transaction).notifier).state = draft;
  }

  void _changeType(WidgetRef ref, TransactionFormDraft draft, String type) {
    // switchType() swaps the active tab while preserving each tab's own
    // categoryId, title, and amount independently.
    _updateDraft(ref, draft.switchType(type));
  }

  Future<void> _pickDateTime(
    BuildContext context,
    WidgetRef ref,
    TransactionFormDraft draft,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: draft.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(draft.date),
    );
    final selectedTime = time ?? TimeOfDay.fromDateTime(draft.date);
    _updateDraft(
      ref,
      draft.copyWith(
        date: DateTime(
          date.year,
          date.month,
          date.day,
          selectedTime.hour,
          selectedTime.minute,
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    TransactionFormDraft draft,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (draft.categoryId == null) {
      _showMessage(context, 'Select category');
      return;
    }
    if (draft.title == null || draft.title!.trim().isEmpty) {
      _showMessage(context, 'Enter a title');
      return;
    }
    _updateDraft(ref, draft.copyWith(isSaving: true));
    try {
      String? walletId = ref.read(selectedWalletIdProvider);
      final wallets = ref.read(walletsProvider).value ?? [];
      walletId ??= wallets.isEmpty ? null : wallets.first.id;
      if (walletId == null) {
        if (context.mounted) _showMessage(context, 'Create a wallet first');
        return;
      }
      final notifier = ref.read(transactionsProvider.notifier);
      if (transaction == null) {
        await notifier.create(
          title: draft.title!.trim(),
          amount: double.parse(draft.amount),
          type: draft.type,
          categoryId: draft.categoryId!,
          walletId: walletId,
          date: draft.date.toIso8601String(),
          note: draft.note.trim().isEmpty ? null : draft.note.trim(),
        );
      } else {
        await notifier.updateTransaction(
          transaction!.copyWith(
            title: draft.title!.trim(),
            amount: double.parse(draft.amount),
            type: draft.type,
            categoryId: draft.categoryId,
            date: draft.date.toIso8601String(),
            note: draft.note.trim().isEmpty ? null : draft.note.trim(),
          ),
        );
      }
      if (context.mounted) {
        Navigator.of(context).pop(transaction == null ? 'created' : 'saved');
      }
    } catch (error) {
      if (context.mounted) _showMessage(context, error.toString());
    } finally {
      if (context.mounted) _updateDraft(ref, draft.copyWith(isSaving: false));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.draft, required this.onChanged});

  final TransactionFormDraft draft;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'expense', label: Text('Expense')),
        ButtonSegment(value: 'income', label: Text('Income')),
      ],
      selected: {draft.type},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _CategorySelector extends ConsumerWidget {
  const _CategorySelector({required this.transaction, required this.draft});

  final TransactionModel? transaction;
  final TransactionFormDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.category,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () => _addCategory(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Category'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        categories.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) => Text(error.toString()),
          data: (items) {
            final visible = items
                .where(
                  (category) =>
                      category.type == draft.type &&
                      !category.isHidden &&
                      !category.isArchived,
                )
                .toList();
            final sorted = _sortCategories(visible, transactions);
            CategoryModel? selectedCategory;
            for (final category in sorted) {
              if (category.id == draft.categoryId) {
                selectedCategory = category;
                break;
              }
            }

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: sorted.isEmpty
                  ? null
                  : () async {
                      final category =
                          await showModalBottomSheet<CategoryModel>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => _CategoryPickerSheet(
                              categories: sorted,
                              type: draft.type,
                              selectedCategoryId: selectedCategory?.id,
                            ),
                          );
                      if (category != null && context.mounted) {
                        ref
                            .read(transactionFormProvider(transaction).notifier)
                            .state = draft.selectCategory(
                          category.id,
                        );
                      }
                    },
              child: Container(
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    if (selectedCategory case final selected?)
                      _CategoryIcon(category: selected, size: 42)
                    else
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedCategory?.name ?? 'Choose a category',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedCategory == null
                                ? 'Tap to browse ${sorted.length} categories'
                                : 'Tap to change category',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<CategoryModel> _sortCategories(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) {
    final usageCounts = <String, int>{};
    for (final tx in transactions) {
      usageCounts[tx.categoryId] = (usageCounts[tx.categoryId] ?? 0) + 1;
    }

    const priorityKeywords = [
      'food',
      'transport',
      'transportation',
      'bills',
      'bill',
      'housing',
      'house',
      'rent',
      'shopping',
      'groceries',
      'grocery',
      'dining',
      'utilities',
      'salary',
      'entertainment',
      'health',
      'healthcare',
      'education',
      'general',
    ];

    int score(CategoryModel c) {
      final count = usageCounts[c.id] ?? 0;
      final name = c.name.toLowerCase().trim();
      final idx = priorityKeywords.indexWhere((k) => name.contains(k));
      int pts = count * 1000;
      if (idx != -1) {
        pts += (100 - idx);
      }
      return pts;
    }

    final sorted = List<CategoryModel>.from(categories);
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await _askForName(context, 'Add category', 'Category name');
    if (name == null) return;
    final category = await ref
        .read(categoriesProvider.notifier)
        .create(
          name: name,
          type: draft.type,
          icon: draft.type == 'income' ? 'work' : 'shopping_bag',
          color: draft.type == 'income' ? '#2ECC71' : '#FF6B6B',
        );
    ref.read(transactionFormProvider(transaction).notifier).state = draft
        .selectCategory(category.id);
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.type,
    required this.selectedCategoryId,
  });

  final List<CategoryModel> categories;
  final String type;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = type == 'income'
        ? 'Choose income category'
        : 'Choose category';

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select one to organize your transaction',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = (constraints.maxWidth / 96)
                      .floor()
                      .clamp(4, 8);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.84,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.id == selectedCategoryId;
                      return _CategoryChoiceTile(
                        category: category,
                        isSelected: isSelected,
                        onTap: () => Navigator.of(context).pop(category),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChoiceTile extends StatelessWidget {
  const _CategoryChoiceTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.48)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
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
                  _CategoryIcon(category: category, size: 34),
                  if (isSelected)
                    Positioned(
                      right: -4,
                      top: -4,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category, required this.size});

  final CategoryModel category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = categoryColorFromHex(category.color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        categoryIconFromName(category.icon),
        color: tint,
        size: size * 0.52,
      ),
    );
  }
}

Future<String?> _askForName(
  BuildContext context,
  String title,
  String hint,
) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).then((value) => value == null || value.isEmpty ? null : value);
}

class _TitleField extends ConsumerWidget {
  const _TitleField({required this.transaction, required this.draft});

  final TransactionModel? transaction;
  final TransactionFormDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomTextField(
      initialValue: draft.title ?? '',
      label: AppStrings.title,
      hint: 'What was this transaction for?',
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
      onChanged: (value) =>
          ref.read(transactionFormProvider(transaction).notifier).state = draft
              .copyWith(title: value),
    );
  }
}
