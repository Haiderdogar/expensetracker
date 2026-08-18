import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../providers/database_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/transaction_model.dart';

final _initializedAddTxProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
final _amountProvider = StateProvider.autoDispose<String>((ref) => '');
final _noteProvider = StateProvider.autoDispose<String>((ref) => '');
final _typeProvider = StateProvider.autoDispose<String>((ref) => 'expense');
final _categoryIdProvider = StateProvider.autoDispose<String?>((ref) => null);
final _dateProvider = StateProvider.autoDispose<DateTime>(
  (ref) => DateTime.now(),
);
final _loadingProvider = StateProvider.autoDispose<bool>((ref) => false);

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key, this.transaction});

  final TransactionModel? transaction;

  bool get _isEditing => transaction != null;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        // Initialize once when editing
        final initialized = ref.watch(_initializedAddTxProvider);
        if (!initialized && _isEditing) {
           final t = transaction!;
           ref.read(_titleProvider.notifier).state = t.title;
           ref.read(_amountProvider.notifier).state = t.amount.toString();
           ref.read(_noteProvider.notifier).state = t.note ?? '';
           ref.read(_typeProvider.notifier).state = t.type;
           ref.read(_categoryIdProvider.notifier).state = t.categoryId;
           // keep existing wallet on edit (wallet selection removed from UI)
           ref.read(_dateProvider.notifier).state = DateTime.parse(t.date);
           ref.read(_initializedAddTxProvider.notifier).state = true;
        }

        final title = ref.watch(_titleProvider);
        final amount = ref.watch(_amountProvider);
        final note = ref.watch(_noteProvider);
        final type = ref.watch(_typeProvider);
        final categoryId = ref.watch(_categoryIdProvider);
        final date = ref.watch(_dateProvider);
        final loading = ref.watch(_loadingProvider);

        final categoriesAsync = ref.watch(categoriesProvider);

        final categories = (categoriesAsync.value ?? [])
            .where((c) => c.type == type)
            .toList();

        final formKey = GlobalKey<FormState>();

        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) ref.read(_dateProvider.notifier).state = picked;
        }

        Future<void> save() async {
          if (!formKey.currentState!.validate()) return;
          if (categoryId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Select category')),
            );
            return;
          }

          ref.read(_loadingProvider.notifier).state = true;
          try {
            final parsedAmount = double.parse(amount);
            final notifier = ref.read(transactionsProvider.notifier);

            // Determine walletId to use: prefer selectedWalletIdProvider, else first available wallet
            String? walletIdToUse = ref.read(selectedWalletIdProvider);
            if (walletIdToUse == null) {
              final wallets = ref.read(walletsProvider).value ?? [];
              if (wallets.isNotEmpty) {
                walletIdToUse = wallets.first.id;
              }
            }

            if (walletIdToUse == null) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a wallet first')));
              return;
            }

            if (_isEditing) {
              await notifier.updateTransaction(
                transaction!.copyWith(
                  title: title.trim(),
                  amount: parsedAmount,
                  type: type,
                  categoryId: categoryId,
                  date: Formatters.isoDateTimeWithCurrentTime(date),
                  note: note.trim().isEmpty ? null : note.trim(),
                ),
              );
            } else {
              await notifier.create(
                title: title.trim(),
                amount: parsedAmount,
                type: type,
                categoryId: categoryId,
                walletId: walletIdToUse,
                date: Formatters.isoDateTimeWithCurrentTime(date),
                note: note.trim().isEmpty ? null : note.trim(),
              );
            }

            Navigator.of(context).pop();
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          } finally {
            ref.read(_loadingProvider.notifier).state = false;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing
                  ? AppStrings.editTransaction
                  : AppStrings.addTransaction,
            ),
          ),
          body: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense')),
                    ButtonSegment(value: 'income', label: Text('Income')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) {
                    ref.read(_typeProvider.notifier).state = s.first;
                    ref.read(_categoryIdProvider.notifier).state = null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  initialValue: title,
                  label: AppStrings.title,
                  onChanged: (v) => ref.read(_titleProvider.notifier).state = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  initialValue: amount,
                  label: AppStrings.amount,
                  onChanged: (v) =>
                      ref.read(_amountProvider.notifier).state = v,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // show current currency symbol as prefix
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(ref.watch(currencySymbolProvider).value ?? '\$'),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.category,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final name = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) {
                            final controller = TextEditingController();
                            return AlertDialog(
                              title: const Text('Add category'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Category name',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    dialogContext,
                                  ).pop(controller.text.trim()),
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                        if (name == null || name.isEmpty) return;
                        final added = await ref
                            .read(categoriesProvider.notifier)
                            .create(
                              name: name,
                              type: type,
                              icon: type == 'income' ? 'work' : 'shopping_bag',
                              color: type == 'income' ? '#2ECC71' : '#FF6B6B',
                            );
                        ref.read(_categoryIdProvider.notifier).state = added.id;
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(e.toString()),
                  data: (allCategories) {
                    final visible = allCategories
                        .where((c) => c.type == type)
                        .toList();
                    if (visible.isEmpty) {
                      return const Text(
                        'No categories available. Add one to continue.',
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: visible.map((c) {
                        final selected = categoryId == c.id;
                        return GestureDetector(
                          onLongPress: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dctx) => AlertDialog(
                                title: const Text('Delete category'),
                                content: Text('Delete "${c.name}"? This cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await ref.read(categoriesProvider.notifier).delete(c.id);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
                              } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            }
                          },
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: selected,
                            onSelected: (_) => ref.read(_categoryIdProvider.notifier).state = c.id,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Currency picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currency'),
                  // show currency code (e.g., PKR, USD) instead of an icon
                  subtitle: Consumer(builder: (cctx, cref, _) {
                    final codeAsync = cref.watch(currencyCodeProvider);
                    final symbolAsync = cref.watch(currencySymbolProvider);
                    return codeAsync.when(
                      loading: () => Text(symbolAsync.value ?? '\$'),
                      error: (_, __) => Text(symbolAsync.value ?? '\$'),
                      data: (code) => Text(code ?? (symbolAsync.value ?? '\$')),
                    );
                  }),
                  trailing: TextButton(
                    onPressed: () {
                      showCurrencyPicker(
                        context: context,
                        showFlag: true,
                        showCurrencyName: true,
                        showCurrencyCode: true,
                        showSearchField: true,
                        theme: CurrencyPickerThemeData(
                          flagSize: 24,
                          titleTextStyle: Theme.of(context).textTheme.titleMedium,
                          subtitleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                          bottomSheetHeight: MediaQuery.of(context).size.height * 0.6,
                          inputDecoration: InputDecoration(
                            labelText: 'Search',
                            hintText: 'Start typing to search',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).hintColor.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                        onSelect: (Currency currency) async {
                          // Save symbol and code in settings
                          try {
                            await ref.read(databaseHelperProvider).setCurrencySymbol(currency.symbol);
                            await ref.read(databaseHelperProvider).setSetting('currency_code', currency.code);
                            ref.invalidate(currencySymbolProvider);
                            ref.invalidate(currencyCodeProvider);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Currency set to ${currency.code}')));
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                      );
                    },
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.date),
                  subtitle: Text(Formatters.date(date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: pickDate,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  initialValue: note,
                  label: AppStrings.note,
                  onChanged: (v) => ref.read(_noteProvider.notifier).state = v,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: AppStrings.save,
                  isLoading: loading,
                  onPressed: save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
