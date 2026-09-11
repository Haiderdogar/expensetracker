import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../analytics_data_providers.dart';

class AnalyticsCategoryList extends ConsumerWidget {
  const AnalyticsCategoryList({
    super.key,
    required this.items,
    this.selectedIndex,
    required this.onSelect,
  });

  final List<CategoryBreakdownItem> items;
  final int? selectedIndex;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 520 ? 3 : 2;
        final rows = <Widget>[];

        for (var i = 0; i < items.length; i += crossAxisCount) {
          final end = (i + crossAxisCount > items.length) ? items.length : i + crossAxisCount;
          final rowItems = items.sublist(i, end);
          final isLastRow = end >= items.length;

          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 0 : 8),
              child: Row(
                children: [
                  for (var j = 0; j < rowItems.length; j++) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _buildTile(
                        context,
                        i + j,
                        rowItems[j],
                        symbol,
                        theme,
                        isDark,
                      ),
                    ),
                  ],
                  // If the last row is uneven, fill remaining columns with empty space
                  for (var k = rowItems.length; k < crossAxisCount; k++) ...[
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    int index,
    CategoryBreakdownItem item,
    String symbol,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onSelect(isSelected ? null : index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.14)
              : (isDark ? AppColors.deepForest : AppColors.gray50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? item.color
                : (isDark ? Colors.white12 : AppColors.gray200),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Mini Icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                item.icon,
                size: 15,
                color: item.color,
              ),
            ),
            const SizedBox(width: 8),

            // Title & Percentage + Amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.currency(item.amount, symbol: symbol),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
