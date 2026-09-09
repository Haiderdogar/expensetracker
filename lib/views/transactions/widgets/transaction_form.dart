import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_model.dart';
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
        final categories = ref.watch(categoriesProvider);
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TypeSelector(
                draft: draft,
                categories: categories.value,
                onChanged: (type) => _changeType(ref, draft, categories.value, type),
              ),
              const SizedBox(height: 16),
              _CategorySelector(transaction: transaction, draft: draft),
              if (draft.categoryId != null) ...[
                const SizedBox(height: 12),
                _SubcategorySelector(transaction: transaction, draft: draft),
              ],
              const SizedBox(height: 16),
              CustomTextField(
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
    List<CategoryModel>? categories,
    String type,
  ) {
    var updated = draft.copyWith(type: type);
    final matching = categories
            ?.where((category) => category.id == draft.categoryId)
            .toList() ??
        const <CategoryModel>[];
    if (matching.isNotEmpty && matching.first.type != type) {
      updated = updated.clearCategory();
    }
    _updateDraft(ref, updated);
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
  const _TypeSelector({required this.draft, required this.categories, required this.onChanged});

  final TransactionFormDraft draft;
  final List<CategoryModel>? categories;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.category, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        categories.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(error.toString()),
          data: (items) {
            final visible = items.where((category) => category.type == draft.type).toList();
            return Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: visible.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: category.id == draft.categoryId,
                          onSelected: (_) => ref.read(transactionFormProvider(transaction).notifier).state =
                              draft.selectCategory(category.id),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Add category',
                  icon: const Icon(Icons.add),
                  onPressed: () => _addCategory(context, ref),
                ),
              ],
            );
          },
        ),
      ],
    );
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
        draft.selectCategory(category.id).copyWith(subcategory: 'General');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subcategory', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ref.watch(subcategoriesProvider(categoryId)).when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(error.toString()),
                data: (items) => items.isEmpty
                    ? const Text('No subcategories yet. Add one to continue.')
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: items.map((item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item.name),
                              selected: item.name == draft.subcategory,
                              onSelected: (_) => ref.read(transactionFormProvider(transaction).notifier).state =
                                  draft.copyWith(subcategory: item.name),
                            ),
                          )).toList(),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Add subcategory',
              icon: const Icon(Icons.add),
              onPressed: () => _addSubcategory(context, ref, categoryId),
            ),
          ],
        ),
      ],
    );
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
