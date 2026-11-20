import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../models/transaction_model.dart';
import 'transactions_ui_providers.dart';
import 'widgets/transaction_delete_button.dart';
import 'widgets/transaction_form.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key, this.transaction, this.initialType});

  // Leave room for an input when a keyboard reduces the available body height.
  static const _minimumBodyHeightWithAd = 128.0;

  final TransactionModel? transaction;
  final String? initialType;

  @override
  Widget build(BuildContext context) {
    final isEditing = transaction != null;
    // Reuse these widgets across keyboard/layout changes so the form keeps its
    // key, focus, and draft, and the initial type is not applied again.
    final form = TransactionForm(transaction: transaction);
    final initialTypeBinder = initialType != null && !isEditing
        ? _InitialTypeBinder(initialType: initialType!)
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit ${_capitalize(transaction!.type)}'
              : AppStrings.addTransaction,
        ),
        actions: isEditing
            ? [TransactionDeleteButton(transaction: transaction!)]
            : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?initialTypeBinder,
            if (!isEditing && constraints.maxHeight >= _minimumBodyHeightWithAd)
              const AppBannerAd(),
            Expanded(child: form),
          ],
        ),
      ),
    );
  }
}

class _InitialTypeBinder extends ConsumerWidget {
  const _InitialTypeBinder({required this.initialType});

  final String initialType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(transactionInitialTypeProvider) != initialType) {
        ref.read(transactionInitialTypeProvider.notifier).state = initialType;
      }
    });
    return const SizedBox.shrink();
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
