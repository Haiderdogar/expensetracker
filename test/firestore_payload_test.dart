import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/models/category_model.dart';
import 'package:expensetracker/models/transaction_model.dart';

void main() {
  test('category Firestore payload contains only cloud fields', () {
    final payload = const CategoryModel(
      id: 'category-id',
      userId: 'user-id',
      walletId: 'wallet-id',
      name: 'Food',
      type: 'expense',
      icon: 'restaurant',
      color: '#ffffff',
      updatedAt: '2026-09-17T00:00:00.000Z',
    ).toFirestore();

    expect(payload, {
      'name': 'Food',
      'type': 'expense',
      'updatedAt': '2026-09-17T00:00:00.000Z',
    });
  });

  test('transaction Firestore payload contains only cloud fields', () {
    final payload = const TransactionModel(
      id: 'transaction-id',
      userId: 'user-id',
      walletId: 'wallet-id',
      title: 'Groceries',
      amount: 42.5,
      type: 'expense',
      categoryId: 'category-id',
      date: '2026-09-17',
      note: 'Weekly shopping',
      updatedAt: '2026-09-17T00:00:00.000Z',
    ).toFirestore();

    expect(payload, {
      'amount': 42.5,
      'categoryId': 'category-id',
      'date': '2026-09-17',
      'note': 'Weekly shopping',
      'title': 'Groceries',
      'type': 'expense',
      'updatedAt': '2026-09-17T00:00:00.000Z',
    });
  });
}
