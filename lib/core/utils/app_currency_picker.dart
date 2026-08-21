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
      subtitleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).hintColor,
      ),
      bottomSheetHeight: MediaQuery.of(context).size.height * 0.6,
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
