import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'wallet_provider.dart';

part 'transaction_provider.g.dart';

@Riverpod(keepAlive: true)
class Transactions extends _$Transactions {
  @override
  Future<List<TransactionModel>> build() => _fetchAll();

  Future<List<TransactionModel>> _fetchAll() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final rows = await db.query(
        DatabaseTables.transactions,
        orderBy: 'date DESC',
      );
      return rows.map(TransactionModel.fromMap).toList();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAll);
  }

  Future<void> add(TransactionModel transaction) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.insert(DatabaseTables.transactions, transaction.toMap());
      final delta = transaction.isIncome ? transaction.amount : -transaction.amount;
      await ref.read(walletsProvider.notifier).updateBalance(
            transaction.walletId,
            delta,
          );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final existing = await db.query(
        DatabaseTables.transactions,
        where: 'id = ?',
        whereArgs: [transaction.id],
        limit: 1,
      );
      if (existing.isEmpty) throw ErrorHandler.from(Exception('not found'));

      final old = TransactionModel.fromMap(existing.first);
      final oldDelta = old.isIncome ? -old.amount : old.amount;
      await ref.read(walletsProvider.notifier).updateBalance(old.walletId, oldDelta);

      await db.update(
        DatabaseTables.transactions,
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      final newDelta = transaction.isIncome ? transaction.amount : -transaction.amount;
      await ref.read(walletsProvider.notifier).updateBalance(
            transaction.walletId,
            newDelta,
          );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final existing = await db.query(
        DatabaseTables.transactions,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isEmpty) return;

      final old = TransactionModel.fromMap(existing.first);
      final delta = old.isIncome ? -old.amount : old.amount;
      await ref.read(walletsProvider.notifier).updateBalance(old.walletId, delta);

      await db.delete(
        DatabaseTables.transactions,
        where: 'id = ?',
        whereArgs: [id],
      );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<TransactionModel> create({
    required String subcategory,
    required double amount,
    required String type,
    required String categoryId,
    required String walletId,
    required String date,
    String? note,
  }) async {
    const uuid = Uuid();
    final transaction = TransactionModel(
      id: uuid.v4(),
      subcategory: subcategory,
      amount: amount,
      type: type,
      categoryId: categoryId,
      walletId: walletId,
      date: date,
      note: note,
    );
    await add(transaction);
    return transaction;
  }

  Future<void> transfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final txDate = (date ?? DateTime.now()).toIso8601String();

      final walletRows = await db.query(DatabaseTables.wallets);
      final wallets = walletRows.map(WalletModel.fromMap).toList();
      final fromWallet = wallets.firstWhere(
        (w) => w.id == fromWalletId,
        orElse: () => WalletModel(id: fromWalletId, name: 'Wallet', balance: 0),
      );
      final toWallet = wallets.firstWhere(
        (w) => w.id == toWalletId,
        orElse: () => WalletModel(id: toWalletId, name: 'Wallet', balance: 0),
      );

      final catRows = await db.query(DatabaseTables.categories, limit: 1);
      final fallbackCatId = catRows.isNotEmpty ? catRows.first['id'] as String : '';

      const uuid = Uuid();
      await db.transaction((txn) async {
        await txn.rawUpdate(
          'UPDATE ${DatabaseTables.wallets} SET balance = balance - ? WHERE id = ?',
          [amount, fromWalletId],
        );
        await txn.rawUpdate(
          'UPDATE ${DatabaseTables.wallets} SET balance = balance + ? WHERE id = ?',
          [amount, toWalletId],
        );

        final outTx = TransactionModel(
          id: uuid.v4(),
          subcategory: 'Transfer to ${toWallet.name}',
          amount: amount,
          type: 'transfer',
          categoryId: fallbackCatId,
          walletId: fromWalletId,
          date: txDate,
          note: note,
        );
        await txn.insert(DatabaseTables.transactions, outTx.toMap());

        final inTx = TransactionModel(
          id: uuid.v4(),
          subcategory: 'Transfer from ${fromWallet.name}',
          amount: amount,
          type: 'transfer',
          categoryId: fallbackCatId,
          walletId: toWalletId,
          date: txDate,
          note: note,
        );
        await txn.insert(DatabaseTables.transactions, inTx.toMap());
      });

      await refresh();
      await ref.read(walletsProvider.notifier).refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}

@riverpod
Future<List<TransactionModel>> recentTransactions(Ref ref) async {
  final all = await ref.watch(transactionsProvider.future);
  return all.take(5).toList();
}

@riverpod
Future<double> totalIncome(Ref ref) async {
  final all = await ref.watch(transactionsProvider.future);
  return all.where((t) => t.isIncome).fold<double>(0.0, (s, t) => s + t.amount);
}

@riverpod
Future<double> totalExpense(Ref ref) async {
  final all = await ref.watch(transactionsProvider.future);
  return all.where((t) => t.isExpense).fold<double>(0.0, (s, t) => s + t.amount);
}

@riverpod
Future<List<TransactionModel>> filteredTransactions(
  Ref ref, {
  String? type,
  String? search,
  List<String>? categories,
  DateTime? month,
}) async {
  final all = await ref.watch(transactionsProvider.future);
  final allCategories = await ref.watch(categoriesProvider.future);

  // If a specific type is selected ('income' or 'expense'), only apply category
  // filters belonging to that type. In 'All' (type == null), all category filters apply.
  final applicableCategories = categories?.where((catId) {
    if (type == null) return true;
    final cat = allCategories.where((c) => c.id == catId).firstOrNull;
    return cat == null || cat.type == type;
  }).toSet();

  final hasCategoryFilter =
      applicableCategories != null && applicableCategories.isNotEmpty;

  return all.where((t) {
    if (type != null && t.type != type) return false;
    if (hasCategoryFilter && !applicableCategories.contains(t.categoryId)) {
      return false;
    }
    if (search != null && search.isNotEmpty) {
      if (!t.subcategory.toLowerCase().contains(search.toLowerCase())) return false;
    }
    if (month != null) {
      final d = DateTime.parse(t.date);
      if (d.year != month.year || d.month != month.month) return false;
    }
    return true;
  }).toList();
}

final currentMonthIncomeProvider = FutureProvider<double>((ref) async {
  final all = await ref.watch(transactionsProvider.future);
  final selectedWalletId = ref.watch(selectedWalletIdProvider);
  final now = DateTime.now();
  return all.where((t) {
    if (!t.isIncome) return false;
    if (selectedWalletId != null && t.walletId != selectedWalletId) return false;
    final d = DateTime.tryParse(t.date);
    if (d == null) return false;
    return d.year == now.year && d.month == now.month;
  }).fold<double>(0.0, (s, t) => s + t.amount);
});

final currentMonthExpenseProvider = FutureProvider<double>((ref) async {
  final all = await ref.watch(transactionsProvider.future);
  final selectedWalletId = ref.watch(selectedWalletIdProvider);
  final now = DateTime.now();
  return all.where((t) {
    if (!t.isExpense) return false;
    if (selectedWalletId != null && t.walletId != selectedWalletId) return false;
    final d = DateTime.tryParse(t.date);
    if (d == null) return false;
    return d.year == now.year && d.month == now.month;
  }).fold<double>(0.0, (s, t) => s + t.amount);
});

// Always returns the single wallet's balance (multi-wallet not supported).
final dashboardDisplayBalanceProvider = FutureProvider<double>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  return wallets.isNotEmpty ? wallets.first.balance : 0.0;
});
