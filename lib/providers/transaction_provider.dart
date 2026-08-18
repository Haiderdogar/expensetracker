import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/transaction_model.dart';
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
    required String title,
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
      title: title,
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
  final catSet = categories == null ? null : categories.toSet();
  return all.where((t) {
    if (type != null && t.type != type) return false;
    if (catSet != null && catSet.isNotEmpty && !catSet.contains(t.categoryId)) return false;
    if (search != null && search.isNotEmpty) {
      if (!t.title.toLowerCase().contains(search.toLowerCase())) return false;
    }
    if (month != null) {
      final d = DateTime.parse(t.date);
      if (d.year != month.year || d.month != month.month) return false;
    }
    return true;
  }).toList();
}
