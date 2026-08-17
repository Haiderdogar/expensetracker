import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/transaction_model.dart';

final _initializedAddTxProvider = StateProvider.autoDispose<bool>((ref) => false);
final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
final _amountProvider = StateProvider.autoDispose<String>((ref) => '');
final _noteProvider = StateProvider.autoDispose<String>((ref) => '');
final _typeProvider = StateProvider.autoDispose<String>((ref) => 'expense');
final _categoryIdProvider = StateProvider.autoDispose<String?>((ref) => null);
final _walletIdProvider = StateProvider.autoDispose<String?>((ref) => null);
final _dateProvider = StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final _loadingProvider = StateProvider.autoDispose<bool>((ref) => false);

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key, this.transaction});

  final TransactionModel? transaction;

  bool get _isEditing => transaction != null;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      // Initialize once when editing
      final initialized = ref.watch(_initializedAddTxProvider);
      if (!initialized && _isEditing) {
        final t = transaction!;
        ref.read(_titleProvider.notifier).state = t.title;
        ref.read(_amountProvider.notifier).state = t.amount.toString();
        ref.read(_noteProvider.notifier).state = t.note ?? '';
        ref.read(_typeProvider.notifier).state = t.type;
        ref.read(_categoryIdProvider.notifier).state = t.categoryId;
        ref.read(_walletIdProvider.notifier).state = t.walletId;
        ref.read(_dateProvider.notifier).state = DateTime.parse(t.date);
        ref.read(_initializedAddTxProvider.notifier).state = true;
      }

      final title = ref.watch(_titleProvider);
      final amount = ref.watch(_amountProvider);
      final note = ref.watch(_noteProvider);
      final type = ref.watch(_typeProvider);
      final categoryId = ref.watch(_categoryIdProvider);
      final walletId = ref.watch(_walletIdProvider);
      final date = ref.watch(_dateProvider);
      final loading = ref.watch(_loadingProvider);

      final categoriesAsync = ref.watch(categoriesProvider);
      final walletsAsync = ref.watch(walletsProvider);

      final categories = (categoriesAsync.value ?? []).where((c) => c.type == type).toList();

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
        if (categoryId == null || walletId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select category and wallet')),
          );
          return;
        }

        ref.read(_loadingProvider.notifier).state = true;
        try {
          final parsedAmount = double.parse(amount);
          final notifier = ref.read(transactionsProvider.notifier);

          if (_isEditing) {
            await notifier.updateTransaction(transaction!.copyWith(
              title: title.trim(),
              amount: parsedAmount,
              type: type,
              categoryId: categoryId,
              walletId: walletId,
              date: Formatters.isoDate(date),
              note: note.trim().isEmpty ? null : note.trim(),
            ));
          } else {
            await notifier.create(
              title: title.trim(),
              amount: parsedAmount,
              type: type,
              categoryId: categoryId,
              walletId: walletId,
              date: Formatters.isoDate(date),
              note: note.trim().isEmpty ? null : note.trim(),
            );
          }

          Navigator.of(context).pop();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        } finally {
          ref.read(_loadingProvider.notifier).state = false;
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? AppStrings.editTransaction : AppStrings.addTransaction),
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
                onChanged: (v) => ref.read(_amountProvider.notifier).state = v,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(AppStrings.category, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                decoration: const InputDecoration(hintText: 'Select category'),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => ref.read(_categoryIdProvider.notifier).state = v,
              ),
              const SizedBox(height: 16),
              Text(AppStrings.wallet, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              walletsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (wallets) => DropdownButtonFormField<String>(
                  initialValue: walletId ?? (wallets.isNotEmpty ? wallets.first.id : null),
                  decoration: const InputDecoration(hintText: 'Select wallet'),
                  items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                  onChanged: (v) => ref.read(_walletIdProvider.notifier).state = v,
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
    });
  }
}
