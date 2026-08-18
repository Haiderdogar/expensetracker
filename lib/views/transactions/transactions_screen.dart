import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/global_keys.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/shimmer_loader.dart';
import 'add_transaction_screen.dart';
import 'widgets/transaction_filter.dart';
import 'widgets/transaction_tile.dart';

final _searchProvider = StateProvider<String>((ref) => '');
final _typeFilterProvider = StateProvider<String?>((ref) => null);
final _categoryFilterProvider = StateProvider<List<String>?>((ref) => null);

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final type = ref.watch(_typeFilterProvider);
        final search = ref.watch(_searchProvider);
        final categoryFilter = ref.watch(_categoryFilterProvider);
        final transactionsAsync = ref.watch(
          filteredTransactionsProvider(type: type, search: search, categories: categoryFilter),
        );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
            ),
            title: const Text(AppStrings.transactions),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
              ),
              child: const Icon(Icons.add),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TransactionFilter(
                  selectedType: type,
                  selectedCategories: categoryFilter,
                  onTypeChanged: (v) => ref.read(_typeFilterProvider.notifier).state = v,
                  onSearchChanged: (v) => ref.read(_searchProvider.notifier).state = v,
                  onCategorySelected: (v) => ref.read(_categoryFilterProvider.notifier).state = v,
                ),
              ),
              Expanded(
                child: transactionsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ShimmerList(),
                  ),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(child: Text(AppStrings.noTransactions));
                    }

                    final grouped = <String, List<dynamic>>{};
                    for (final t in transactions) {
                      final key = Formatters.date(DateTime.parse(t.date));
                      grouped.putIfAbsent(key, () => []).add(t);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final key = grouped.keys.elementAt(index);
                        final items = grouped[key]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text(
                                key,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            ...items.map(
                              (t) => TransactionTile(
                                transaction: t,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AddTransactionScreen(transaction: t),
                                  ),
                                ),
                                onDelete: () => ref
                                    .read(transactionsProvider.notifier)
                                    .delete(t.id),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
