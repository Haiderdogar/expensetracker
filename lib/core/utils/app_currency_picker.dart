import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';

void showAppCurrencyPicker({
  required BuildContext context,
  required ValueChanged<Currency> onSelect,
}) {
  showCurrencyPicker(
    context: context,
    showFlag: true,
    showCurrencyName: true,
    showCurrencyCode: true,
    showSearchField: true,
    theme: CurrencyPickerThemeData(
      flagSize: 24,
      titleTextStyle: Theme.of(context).textTheme.titleMedium,
      subtitleTextStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
      // Keep enough room for the system keyboard when the search field has
      // focus. The picker package uses this as a fixed-height sheet.
      bottomSheetHeight: MediaQuery.sizeOf(context).height * 0.45,
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
    ),
    onSelect: onSelect,
  );
}
