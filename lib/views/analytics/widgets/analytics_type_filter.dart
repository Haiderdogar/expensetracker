import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

class AnalyticsTypeFilter extends StatelessWidget {
  const AnalyticsTypeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SegmentedButton<String>(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primaryContainer
              : colors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimaryContainer
              : colors.onSurface,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      ),
      segments: const [
        ButtonSegment(value: 'all', label: Text(AppStrings.viewAll)),
        ButtonSegment(value: 'expense', label: Text(AppStrings.onlyExpense)),
        ButtonSegment(value: 'income', label: Text(AppStrings.onlyIncome)),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
