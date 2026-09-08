import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import 'dashboard_stat_chip.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardSummaryContent();
}

class _DashboardSummaryContent extends StatelessWidget {
  const _DashboardSummaryContent();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final balance = ref.watch(totalBalanceProvider);
        final income = ref.watch(totalIncomeProvider);
        final expense = ref.watch(totalExpenseProvider);
        final symbol = ref.watch(currencySymbolProvider).value ?? '\$';

        if (balance.isLoading || income.isLoading || expense.isLoading) {
          return const ShimmerLoader(height: 160);
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryEmerald,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.totalBalance,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.currency(balance.value ?? 0, symbol: '$symbol '),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  DashboardStatChip(
                    label: AppStrings.income,
                    value: Formatters.currency(income.value ?? 0, symbol: symbol),
                    color: AppColors.incomeGreen,
                  ),
                  const SizedBox(width: 12),
                  DashboardStatChip(
                    label: AppStrings.expense,
                    value: Formatters.currency(expense.value ?? 0, symbol: symbol),
                    color: AppColors.expenseRed,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
