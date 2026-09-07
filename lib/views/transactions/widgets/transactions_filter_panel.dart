import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transactions_ui_providers.dart';
import 'transaction_filter.dart';

class TransactionsFilterPanel extends StatelessWidget {
  const TransactionsFilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TransactionFilter(
        selectedType: ref.watch(transactionTypeFilterProvider),
        selectedCategories: ref.watch(transactionCategoryFilterProvider),
        onTypeChanged: (value) =>
            ref.read(transactionTypeFilterProvider.notifier).state = value,
        onSearchChanged: (value) =>
            ref.read(transactionSearchProvider.notifier).state = value,
        onCategorySelected: (value) =>
            ref.read(transactionCategoryFilterProvider.notifier).state = value,
      ),
    );
  }
}
