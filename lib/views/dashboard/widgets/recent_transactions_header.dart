import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../dashboard_ui_providers.dart';

class RecentTransactionsHeader extends StatelessWidget {
  const RecentTransactionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppStrings.recentTransactions, style: Theme.of(context).textTheme.titleMedium),
        const RecentTransactionFilter(),
      ],
    );
  }
}

class RecentTransactionFilter extends StatelessWidget {
  const RecentTransactionFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(recentTransactionFilterProvider);
        final colors = Theme.of(context).colorScheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected, style: Theme.of(context).textTheme.bodySmall),
            PopupMenuButton<String>(
              tooltip: 'Filter recent transactions',
              icon: const Icon(Icons.filter_list),
              color: colors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 6,
              shadowColor: colors.shadow.withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.outlineVariant),
              ),
              menuPadding: const EdgeInsets.symmetric(vertical: 8),
              initialValue: selected,
              onSelected: (filter) => ref.read(recentTransactionFilterProvider.notifier).state = filter,
              itemBuilder: (context) => recentTransactionFilterOptions
                  .map((filter) => _filterOption(context, filter, selected))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _filterOption(BuildContext context, String filter, String selected) {
    final isSelected = filter == selected;
    final colors = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      value: filter,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(filter, style: TextStyle(color: colors.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}
