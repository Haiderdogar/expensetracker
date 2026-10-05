import 'package:currency_picker/currency_picker.dart';
// The package exposes the picker launcher but not its list widget.
// ignore: implementation_imports
import 'package:currency_picker/src/currency_list_view.dart';
import 'package:flutter/material.dart';

void showAppCurrencyPicker({
  required BuildContext context,
  required ValueChanged<Currency> onSelect,
}) {
  final theme = CurrencyPickerThemeData(
    flagSize: 24,
    titleTextStyle: Theme.of(context).textTheme.titleMedium,
    subtitleTextStyle: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
    inputDecoration: InputDecoration(
      labelText: 'Search',
      hintText: 'Start typing to search',
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).hintColor.withValues(alpha: 0.2),
        ),
      ),
    ),
  );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final mediaQuery = MediaQuery.of(sheetContext);
      final availableHeight =
          mediaQuery.size.height - mediaQuery.viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: SizedBox(
          height: availableHeight > 0
              ? (mediaQuery.size.height * 0.45).clamp(0.0, availableHeight)
              : 0,
          child: CurrencyListView(
            onSelect: onSelect,
            showFlag: true,
            showCurrencyName: true,
            showCurrencyCode: true,
            showSearchField: true,
            theme: theme,
          ),
        ),
      );
    },
  );
}
