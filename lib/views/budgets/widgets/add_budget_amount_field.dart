import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../budgets_ui_providers.dart';

class AddBudgetAmountField extends StatelessWidget {
  const AddBudgetAmountField({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(hintText: 'Budget amount'),
        onChanged: (value) => ref.read(addBudgetAmountProvider.notifier).state = value,
      ),
    );
  }
}
