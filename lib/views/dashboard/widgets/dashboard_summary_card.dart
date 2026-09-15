import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/wallet_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../dashboard_ui_providers.dart';
import 'dashboard_stat_chip.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardSummaryContent();
}

class _DashboardSummaryContent extends ConsumerWidget {
  const _DashboardSummaryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
        final balance = ref.watch(dashboardDisplayBalanceProvider);
        final income = ref.watch(currentMonthIncomeProvider);
        final expense = ref.watch(currentMonthExpenseProvider);
        final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
        final isHidden = ref.watch(dashboardBalanceHiddenProvider);
        final wallets = ref.watch(walletsProvider).value ?? const <WalletModel>[];

        if (balance.isLoading || income.isLoading || expense.isLoading) {
          return const ShimmerLoader(height: 160);
        }

        final accountLabel = wallets.isNotEmpty ? '${wallets.first.name} Balance' : 'Balance';

        final displayBalance = isHidden
            ? '••••••••'
            : Formatters.currency(balance.value ?? 0, symbol: '$symbol ');

        final displayIncome = isHidden
            ? '••••'
            : Formatters.currency(income.value ?? 0, symbol: symbol);

        final displayExpense = isHidden
            ? '••••'
            : Formatters.currency(expense.value ?? 0, symbol: symbol);

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.primaryEmerald,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryEmerald.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      accountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => ref
                        .read(dashboardBalanceHiddenProvider.notifier)
                        .toggle(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayBalance,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  DashboardStatChip(
                    label: 'Income',
                    value: displayIncome,
                    color: AppColors.incomeGreen,
                    icon: Icons.arrow_upward_rounded,
                  ),
                  const SizedBox(width: 12),
                  DashboardStatChip(
                    label: 'Expense',
                    value: displayExpense,
                    color: AppColors.expenseRed,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ],
              ),
            ],
          ),
        );
  }
}
