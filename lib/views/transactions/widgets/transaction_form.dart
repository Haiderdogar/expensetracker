import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
import '../../../models/subcategory_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/subcategory_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../transactions_ui_providers.dart';

class TransactionForm extends StatelessWidget {
  TransactionForm({super.key, this.transaction});

  final TransactionModel? transaction;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final draft = ref.watch(transactionFormProvider(transaction));
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Only allow switching type when creating a new transaction.
              // When editing, the type is locked to the original transaction type.
              if (transaction == null) ...[ 
                _TypeSelector(
                  draft: draft,
                  onChanged: (type) => _changeType(ref, draft, type),
                ),
                const SizedBox(height: 16),
              ],
              _CategorySelector(transaction: transaction, draft: draft),
              if (draft.categoryId != null) ...[
                const SizedBox(height: 12),
                _SubcategorySelector(transaction: transaction, draft: draft),
              ],
              const SizedBox(height: 16),
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
                onChanged: (value) => _updateDraft(ref, draft.copyWith(amount: value)),
              ),
              CustomTextField(
                initialValue: draft.note,
                label: AppStrings.note,
                hint: draft.type == 'income'
                    ? 'Add details of your income'
                    : 'Add details of your expense',
                maxLines: 3,
                onChanged: (value) => _updateDraft(ref, draft.copyWith(note: value)),
              ),
              const SizedBox(height: 16),
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
      },
    );
  }

  void _updateDraft(WidgetRef ref, TransactionFormDraft draft) {
    ref.read(transactionFormProvider(transaction).notifier).state = draft;
  }

  void _changeType(
    WidgetRef ref,
    TransactionFormDraft draft,
    String type,
  ) {
    // switchType() swaps the active tab while preserving each tab's own
    // categoryId, subcategory, and amount independently.
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
        date: DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute),
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
    if (draft.subcategory == null || draft.subcategory!.trim().isEmpty) {
      _showMessage(context, 'Select or add a subcategory');
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
          subcategory: draft.subcategory!.trim(),
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
            subcategory: draft.subcategory!.trim(),
            amount: double.parse(draft.amount),
            type: draft.type,
            categoryId: draft.categoryId,
            date: draft.date.toIso8601String(),
            note: draft.note.trim().isEmpty ? null : draft.note.trim(),
          ),
        );
      }
      if (context.mounted) Navigator.of(context).pop(transaction == null ? 'created' : 'saved');
    } catch (error) {
      if (context.mounted) _showMessage(context, error.toString());
    } finally {
      if (context.mounted) _updateDraft(ref, draft.copyWith(isSaving: false));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _addCategory(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Category'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
            final visible = items.where((category) => category.type == draft.type).toList();
            final sorted = _sortCategories(visible, transactions);
            final isSelectedValid = sorted.any((c) => c.id == draft.categoryId);

            return DropdownMenu<String>(
              key: ValueKey('${draft.type}_${draft.categoryId}'),
              expandedInsets: EdgeInsets.zero,
              requestFocusOnTap: false,
              enableSearch: false,
              hintText: 'Select category',
              initialSelection: isSelectedValid ? draft.categoryId : null,
              trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded),
              menuHeight: 280,
              dropdownMenuEntries: sorted.map((category) {
                return DropdownMenuEntry<String>(
                  value: category.id,
                  label: category.name,
                );
              }).toList(),
              onSelected: (value) {
                if (value != null) {
                  ref.read(transactionFormProvider(transaction).notifier).state =
                      draft.selectCategory(value);
                }
              },
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
    final category = await ref.read(categoriesProvider.notifier).createWithSubcategory(
      name: name,
      subcategoryName: 'General',
      type: draft.type,
      icon: draft.type == 'income' ? 'work' : 'shopping_bag',
      color: draft.type == 'income' ? '#2ECC71' : '#FF6B6B',
    );
    ref.read(transactionFormProvider(transaction).notifier).state =
        draft.selectCategory(category.id);
  }
}

Future<String?> _askForName(BuildContext context, String title, String hint) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: const Text('Save')),
        ],
      );
    },
  ).then((value) => value == null || value.isEmpty ? null : value);
}

class _SubcategorySelector extends ConsumerWidget {
  const _SubcategorySelector({required this.transaction, required this.draft});

  final TransactionModel? transaction;
  final TransactionFormDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = draft.categoryId!;
    final transactions = ref.watch(transactionsProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subcategory',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _addSubcategory(context, ref, categoryId),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Subcategory'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ref.watch(subcategoriesProvider(categoryId)).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) => Text(error.toString()),
          data: (items) {
            final sorted = _sortSubcategories(items, categoryId, transactions);
            final isSelectedValid = sorted.any((s) => s.name == draft.subcategory);

            return DropdownMenu<String>(
              key: ValueKey('${categoryId}_${draft.subcategory}'),
              expandedInsets: EdgeInsets.zero,
              requestFocusOnTap: false,
              enableSearch: false,
              hintText: 'Select subcategory',
              initialSelection: isSelectedValid ? draft.subcategory : null,
              trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded),
              menuHeight: 250,
              dropdownMenuEntries: sorted.map((sub) {
                return DropdownMenuEntry<String>(
                  value: sub.name,
                  label: sub.name,
                );
              }).toList(),
              onSelected: (value) {
                if (value != null) {
                  ref.read(transactionFormProvider(transaction).notifier).state =
                      draft.copyWith(subcategory: value);
                }
              },
            );
          },
        ),
      ],
    );
  }

  List<SubcategoryModel> _sortSubcategories(
    List<SubcategoryModel> subcategories,
    String categoryId,
    List<TransactionModel> transactions,
  ) {
    final usageCounts = <String, int>{};
    for (final tx in transactions) {
      if (tx.categoryId == categoryId && tx.subcategory.isNotEmpty) {
        final key = tx.subcategory.toLowerCase().trim();
        usageCounts[key] = (usageCounts[key] ?? 0) + 1;
      }
    }

    const priorityKeywords = [
      'general',
      'groceries',
      'grocery',
      'restaurant',
      'dining',
      'food',
      'fuel',
      'gas',
      'petrol',
      'bus',
      'metro',
      'train',
      'taxi',
      'uber',
      'electricity',
      'water',
      'internet',
      'wifi',
      'phone',
      'rent',
      'maintenance',
      'clothing',
      'clothes',
      'coffee',
      'snacks',
    ];

    int score(SubcategoryModel s) {
      final name = s.name.toLowerCase().trim();
      final count = usageCounts[name] ?? 0;
      final idx = priorityKeywords.indexWhere((k) => name.contains(k));
      int pts = count * 1000;
      if (idx != -1) {
        pts += (100 - idx);
      }
      return pts;
    }

    final sorted = List<SubcategoryModel>.from(subcategories);
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  Future<void> _addSubcategory(BuildContext context, WidgetRef ref, String categoryId) async {
    final name = await _askForName(context, 'Add subcategory', 'Subcategory name');
    if (name == null || !context.mounted) return;
    try {
      final subcategory = await addSubcategory(ref, categoryId: categoryId, name: name);
      ref.read(transactionFormProvider(transaction).notifier).state =
          draft.copyWith(subcategory: subcategory.name);
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
