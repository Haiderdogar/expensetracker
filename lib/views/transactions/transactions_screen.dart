import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import 'widgets/active_filter_chips.dart';
import 'widgets/transaction_list.dart';
import 'widgets/transactions_add_button.dart';
import 'widgets/transactions_filter_panel.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(AppStrings.transactions),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 90),
        child: TransactionsAddButton(),
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TransactionsFilterPanel(),
          ),
          ActiveFilterChips(),
          Expanded(child: TransactionList()),
        ],
      ),
    );
  }
}
