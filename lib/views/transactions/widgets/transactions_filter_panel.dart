import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transactions_ui_providers.dart';
import 'transaction_filter.dart';

class TransactionsFilterPanel extends ConsumerWidget {
  const TransactionsFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionFilter(
      selectedCategories: ref.watch(selectedCategoryFiltersProvider),
      onSearchChanged: (value) =>
          ref.read(transactionSearchProvider.notifier).state = value,
      onCategorySelected: (value) =>
          ref.read(selectedCategoryFiltersProvider.notifier).state = value,
    );
  }
}
