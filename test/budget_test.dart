import 'package:expensetracker/models/budget_model.dart';
import 'package:expensetracker/models/category_model.dart';
import 'package:expensetracker/providers/budget_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetProgress calculations', () {
    const testCategory = CategoryModel(
      id: 'cat-1',
      name: 'Groceries',
      type: 'expense',
      icon: 'restaurant',
      color: '#10B981',
    );

    test('under budget (< 80%) is not near limit and not over budget', () {
      const budget = BudgetModel(
        id: 'b-1',
        categoryId: 'cat-1',
        amount: 200,
        monthYear: '2025-09',
      );

      final progress = BudgetProgress(
        budget: budget,
        spent: 100, // 50%
        category: testCategory,
      );

      expect(progress.remaining, 100);
      expect(progress.progress, 0.5);
      expect(progress.isOverBudget, isFalse);
      expect(progress.isNearLimit, isFalse);
      expect(progress.categoryName, 'Groceries');
    });

    test('near limit (>= 80% and <= 100%) triggers isNearLimit', () {
      const budget = BudgetModel(
        id: 'b-2',
        categoryId: 'cat-1',
        amount: 200,
        monthYear: '2025-09',
      );

      final progress = BudgetProgress(
        budget: budget,
        spent: 170, // 85%
        category: testCategory,
      );

      expect(progress.remaining, 30);
      expect(progress.progress, 0.85);
      expect(progress.isOverBudget, isFalse);
      expect(progress.isNearLimit, isTrue);
    });

    test('over budget (> 100%) triggers isOverBudget', () {
      const budget = BudgetModel(
        id: 'b-3',
        categoryId: 'cat-1',
        amount: 200,
        monthYear: '2025-09',
      );

      final progress = BudgetProgress(
        budget: budget,
        spent: 240, // 120%
        category: testCategory,
      );

      expect(progress.remaining, -40);
      expect(progress.progress, 1.2);
      expect(progress.isOverBudget, isTrue);
      expect(progress.isNearLimit, isFalse);
    });
  });
}
