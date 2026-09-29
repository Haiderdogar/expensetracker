import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/core/database/database_tables.dart';
import 'package:expensetracker/core/utils/category_utils.dart';

void main() {
  test('built-in categories include additional income and expense options', () {
    final income = DatabaseTables.defaultCategories.where(
      (category) => category['type'] == 'income',
    );
    final expense = DatabaseTables.defaultCategories.where(
      (category) => category['type'] == 'expense',
    );

    expect(income.length, greaterThan(5));
    expect(expense.length, greaterThan(16));
  });

  test('every built-in category has a matching icon', () {
    for (final category in DatabaseTables.defaultCategories) {
      expect(
        categoryIconFromName(category['icon'] as String),
        isNot(Icons.category_outlined),
        reason: 'No matching icon is registered for ${category['name']}',
      );
    }
  });
}
