import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/error_handler.dart';

final _typeProvider = StateProvider.autoDispose<String>((ref) => 'expense');
final _categoryIdProvider = StateProvider.autoDispose<String?>((ref) => null);
final _dateProvider = StateProvider.autoDispose<DateTime>(
  (ref) => DateTime.now(),
);
final _loadingProvider = StateProvider.autoDispose<bool>((ref) => false);

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.transaction});

  final TransactionModel? transaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  bool _editDataInitialized = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        // Initialize form values once when editing.
        if (_isEditing && !_editDataInitialized) {
          _editDataInitialized = true;
          final t = widget.transaction!;
          final parsedDate = DateTime.tryParse(t.date) ?? DateTime.now();
          final safeType = (t.type == 'income' || t.type == 'expense')
              ? t.type
              : 'expense';

          _titleController.text = t.title;
          _amountController.text = t.amount.toString();
          _noteController.text = t.note ?? '';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(_typeProvider.notifier).state = safeType;
            ref.read(_categoryIdProvider.notifier).state =
                t.categoryId.isEmpty ? null : t.categoryId;
            ref.read(_dateProvider.notifier).state = parsedDate;
          });
        }

        final type = ref.watch(_typeProvider);
        final categoryId = ref.watch(_categoryIdProvider);
        final date = ref.watch(_dateProvider);
        final loading = ref.watch(_loadingProvider);

        final categoriesAsync = ref.watch(categoriesProvider);

        // final categories = (categoriesAsync.value ?? [])
        //     .where((c) => c.type == type)
        //     .toList();

        final formKey = GlobalKey<FormState>();

        Future<void> pickDateTime() async {
          // Pick the date first
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (pickedDate == null) return;

          // Then pick the time (default to currently selected time)
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date),
          );

          final timeOfDay = pickedTime ?? TimeOfDay.fromDateTime(date);

          final combined = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            timeOfDay.hour,
            timeOfDay.minute,
          );

          ref.read(_dateProvider.notifier).state = combined;
        }

        Future<void> save() async {
          if (!formKey.currentState!.validate()) return;
          if (categoryId == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Select category')));
            return;
          }

          ref.read(_loadingProvider.notifier).state = true;
          try {
            final title = _titleController.text;
            final amount = _amountController.text;
            final note = _noteController.text;

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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create a wallet first')),
                );
              }
              return;
            }

            if (_isEditing) {
              await notifier.updateTransaction(
                widget.transaction!.copyWith(
                  title: title.trim(),
                  amount: parsedAmount,
                  type: type,
                  categoryId: categoryId,
                  date: date.toIso8601String(),
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
                date: date.toIso8601String(),
                note: note.trim().isEmpty ? null : note.trim(),
              );
            }

            // Indicate success to caller so they can refresh dependent state
            // Return a string so callers can distinguish created vs updated vs deleted.
            if (_isEditing) {
              Navigator.of(context).pop('saved');
            } else {
              Navigator.of(context).pop('created');
            }
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
            actions: _isEditing
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Delete transaction'),
                            content: const Text(
                              'Delete this transaction? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(dctx).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        ref.read(_loadingProvider.notifier).state = true;
                        try {
                          await ref
                              .read(transactionsProvider.notifier)
                              .delete(widget.transaction!.id);
                          // Return a result so callers refresh and can show feedback
                          Navigator.of(context).pop('deleted');
                        } catch (e) {
                          final msg = ErrorHandler.message(e);
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(msg)));
                          }
                        } finally {
                          ref.read(_loadingProvider.notifier).state = false;
                        }
                      },
                    ),
                  ]
                : null,
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
                    final newType = s.first;
                    ref.read(_typeProvider.notifier).state = newType;

                    // Preserve category selection if it's still valid for the new type.
                    // If categories haven't loaded yet, don't change the selection to avoid
                    // modifying providers during build or inconsistent state.
                    final currentCatId = ref.read(_categoryIdProvider);
                    final cats = categoriesAsync.value;
                    if (currentCatId == null || cats == null) return;

                    try {
                      final matching = cats
                          .where((c) => c.id == currentCatId)
                          .toList();
                      if (matching.isEmpty) {
                        // previously selected category no longer exists
                        ref.read(_categoryIdProvider.notifier).state = null;
                        return;
                      }
                      final selectedCat = matching.first;
                      if (selectedCat.type != newType) {
                        // previously selected category doesn't match the newly selected type
                        // clear it so the user is prompted to pick an appropriate category
                        ref.read(_categoryIdProvider.notifier).state = null;
                      }
                    } catch (_) {
                      // On any unexpected error, don't change the selection.
                    }
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
                                content: Text(
                                  'Delete "${c.name}"? This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await ref
                                    .read(categoriesProvider.notifier)
                                    .delete(c.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Category deleted'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            }
                          },
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: selected,
                            onSelected: (_) =>
                                ref.read(_categoryIdProvider.notifier).state =
                                    c.id,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _titleController,
                  label: AppStrings.title,
                  hint: type == 'income'
                      ? 'From where come'
                      : 'Where you spend',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _amountController,
                  label: AppStrings.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // show current currency symbol as prefix with symmetric vertical padding
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      ref.watch(currencySymbolProvider).value ?? '\$',
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${AppStrings.date} & Time'),
                  subtitle: Text(Formatters.dateTime(date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: pickDateTime,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _noteController,
                  label: AppStrings.note,
                  hint: type == 'income'
                      ? 'Add details of your income'
                      : 'Add details of your expense',
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
