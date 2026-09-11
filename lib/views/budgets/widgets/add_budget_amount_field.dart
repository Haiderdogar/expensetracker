import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../budgets_ui_providers.dart';

class AddBudgetAmountField extends ConsumerWidget {
  const AddBudgetAmountField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final initialText = ref.watch(addBudgetAmountProvider);

    return TextFormField(
      initialValue: initialText.isNotEmpty ? initialText : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'Budget amount',
        prefixText: '$symbol ',
        prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onChanged: (value) =>
          ref.read(addBudgetAmountProvider.notifier).state = value.trim(),
    );
  }
}
