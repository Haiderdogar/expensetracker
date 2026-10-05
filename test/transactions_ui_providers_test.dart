import 'package:expensetracker/views/transactions/transactions_ui_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TypeDraft category selection', () {
    const draft = TypeDraft(
      categoryId: 'original-category',
      title: 'Groceries',
      amount: '24.50',
    );

    test('changing category keeps the title and amount', () {
      final updated = draft.selectCategory('new-category');

      expect(updated.categoryId, 'new-category');
      expect(updated.title, 'Groceries');
      expect(updated.amount, '24.50');
    });

    test('clearing category keeps the title and amount', () {
      final updated = draft.clearCategory();

      expect(updated.categoryId, isNull);
      expect(updated.title, 'Groceries');
      expect(updated.amount, '24.50');
    });
  });
}
