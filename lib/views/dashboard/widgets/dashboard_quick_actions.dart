import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../transactions/add_transaction_screen.dart';
import 'transfer_bottom_sheet.dart';

class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Add Income',
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.incomeGreen,
            backgroundColor: AppColors.incomeGreen.withValues(alpha: 0.12),
            onTap: () => _openAddTransaction(context, 'income'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: 'Add Expense',
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.expenseRed,
            backgroundColor: AppColors.expenseRed.withValues(alpha: 0.12),
            onTap: () => _openAddTransaction(context, 'expense'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: 'Transfer',
            icon: Icons.swap_horiz_rounded,
            iconColor: AppColors.primaryEmerald,
            backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.12),
            onTap: () => _openTransfer(context),
          ),
        ),
      ],
    );
  }

  Future<void> _openAddTransaction(BuildContext context, String type) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
    if (result == 'created' && context.mounted) {
      showSuccessSnackBar(
        context,
        '${type[0].toUpperCase()}${type.substring(1)} added successfully',
      );
    }
  }

  void _openTransfer(BuildContext context) {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const TransferBottomSheet(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? colors.surfaceContainerHighest.withValues(alpha: 0.5) : AppColors.gray100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
