import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/models/budget_model.dart';
import 'package:expensetracker/models/category_model.dart';
import 'package:expensetracker/models/note_model.dart';
import 'package:expensetracker/models/transaction_model.dart';
import 'package:expensetracker/models/wallet_model.dart';

void main() {
  test('custom category Firestore payload contains category fields only', () {
    final payload = const CategoryModel(
      id: 'category-id',
      userId: 'user-id',
      walletId: 'wallet-id',
      name: 'Food',
      type: 'expense',
      icon: 'restaurant',
      color: '#ffffff',
      isHidden: true,
      updatedAt: '2026-09-17T00:00:00.000Z',
    ).toFirestore();

    expect(payload, {
      'name': 'Food',
      'type': 'expense',
      'icon': 'restaurant',
      'color': '#ffffff',
      'isArchived': false,
      'updatedAt': '2026-09-17T00:00:00.000Z',
    });
  });

  test('built-in category IDs are stable per account and category', () {
    expect(
      CategoryModel.builtInId('user-id', 'expense', 'Food'),
      'builtin_user-id_expense_food',
    );
    expect(
      CategoryModel.builtInId('user-id', 'expense', 'Food'),
      CategoryModel.builtInId('user-id', 'expense', 'Food'),
    );
    expect(
      CategoryModel.builtInId('user-id', 'expense', 'Food'),
      isNot(CategoryModel.builtInId('another-user', 'expense', 'Food')),
    );
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

  test('wallet Firestore payload omits document and user IDs', () {
    final payload = const WalletModel(
      id: 'wallet-id',
      userId: 'user-id',
      name: 'Main',
      balance: 100,
      updatedAt: '2026-09-17T00:00:00.000Z',
    ).toFirestore();

    expect(payload, {
      'name': 'Main',
      'balance': 100,
      'updatedAt': '2026-09-17T00:00:00.000Z',
    });
  });

  test('budget Firestore payload omits document, user, and wallet IDs', () {
    final payload = const BudgetModel(
      id: 'budget-id',
      userId: 'user-id',
      walletId: 'wallet-id',
      categoryId: 'category-id',
      amount: 250,
      monthYear: '2026-09',
      updatedAt: '2026-09-17T00:00:00.000Z',
    ).toFirestore();

    expect(payload, {
      'categoryId': 'category-id',
      'amount': 250,
      'monthYear': '2026-09',
      'updatedAt': '2026-09-17T00:00:00.000Z',
    });
  });

  test('note Firestore payload omits document, user, and wallet IDs', () {
    final payload = NoteModel(
      id: 'note-id',
      userId: 'user-id',
      walletId: 'wallet-id',
      title: 'Reminder',
      content: 'Pay rent',
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 17),
    ).toFirestore();

    expect(payload, {
      'title': 'Reminder',
      'content': 'Pay rent',
      'createdAt': '2026-09-01T00:00:00.000Z',
      'updatedAt': '2026-09-17T00:00:00.000Z',
    });
  });

  test('Firestore model IDs come from document paths, not stored fields', () {
    expect(
      WalletModel.fromFirestore({
        'id': 'stored-id',
        'userId': 'stored-user',
      }, 'wallet-document-id'),
      isA<WalletModel>()
          .having((wallet) => wallet.id, 'id', 'wallet-document-id')
          .having((wallet) => wallet.userId, 'userId', ''),
    );
    expect(
      BudgetModel.fromFirestore({
        'id': 'stored-id',
        'userId': 'stored-user',
        'walletId': 'stored-wallet',
      }, 'budget-document-id'),
      isA<BudgetModel>()
          .having((budget) => budget.id, 'id', 'budget-document-id')
          .having((budget) => budget.userId, 'userId', '')
          .having((budget) => budget.walletId, 'walletId', ''),
    );
    expect(
      NoteModel.fromFirestore({
        'id': 'stored-id',
        'userId': 'stored-user',
        'walletId': 'stored-wallet',
      }, 'note-document-id'),
      isA<NoteModel>()
          .having((note) => note.id, 'id', 'note-document-id')
          .having((note) => note.userId, 'userId', '')
          .having((note) => note.walletId, 'walletId', ''),
    );
  });
}
