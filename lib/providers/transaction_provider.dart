import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'auth_provider.dart';
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
      ref.watch(localDataEpochProvider);
      final userId = ref.watch(currentUserIdProvider);
      final walletId = ref.watch(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      return await syncRepo.getTransactions(userId, walletId: walletId);
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
      final userId = ref.read(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      final txToSave = transaction.copyWith(userId: userId);
      await syncRepo.saveTransaction(txToSave);

      final delta = transaction.isIncome
          ? transaction.amount
          : -transaction.amount;
      await ref
          .read(walletsProvider.notifier)
          .updateBalance(transaction.walletId, delta);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final walletId = ref.read(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      final existingTxs = await syncRepo.getTransactions(
        userId,
        walletId: walletId,
      );
      final existing = existingTxs
          .where((t) => t.id == transaction.id)
          .toList();
      if (existing.isEmpty) throw ErrorHandler.from(Exception('not found'));

      final old = existing.first;
      final oldDelta = old.isIncome ? -old.amount : old.amount;
      await ref
          .read(walletsProvider.notifier)
          .updateBalance(old.walletId, oldDelta);

      final txToSave = transaction.copyWith(userId: userId);
      await syncRepo.saveTransaction(txToSave);

      final newDelta = transaction.isIncome
          ? transaction.amount
          : -transaction.amount;
      await ref
          .read(walletsProvider.notifier)
          .updateBalance(transaction.walletId, newDelta);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final walletId = ref.read(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      final existingTxs = await syncRepo.getTransactions(
        userId,
        walletId: walletId,
      );
      final existing = existingTxs.where((t) => t.id == id).toList();
      if (existing.isEmpty) return;

      final old = existing.first;
      final delta = old.isIncome ? -old.amount : old.amount;
      await ref
          .read(walletsProvider.notifier)
          .updateBalance(old.walletId, delta);

      await syncRepo.deleteTransaction(id, userId);
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
    final userId = ref.read(currentUserIdProvider);
    final transaction = TransactionModel(
      id: uuid.v4(),
      userId: userId,
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
      final userId = ref.read(currentUserIdProvider);
      final txDate = (date ?? DateTime.now()).toIso8601String();

      final walletRows = await db.query(
        DatabaseTables.wallets,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final wallets = walletRows.map(WalletModel.fromMap).toList();
      final fromWallet = wallets.firstWhere(
        (w) => w.id == fromWalletId,
        orElse: () => WalletModel(
          id: fromWalletId,
          userId: userId,
          name: 'Wallet',
          balance: 0,
        ),
      );
      final toWallet = wallets.firstWhere(
        (w) => w.id == toWalletId,
        orElse: () => WalletModel(
          id: toWalletId,
          userId: userId,
          name: 'Wallet',
          balance: 0,
        ),
      );

      final catRows = await db.query(
        DatabaseTables.categories,
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      final fallbackCatId = catRows.isNotEmpty
          ? catRows.first['id'] as String
          : '';

      const uuid = Uuid();
      final outTx = TransactionModel(
        id: uuid.v4(),
        userId: userId,
        subcategory: 'Transfer to ${toWallet.name}',
        amount: amount,
        type: 'transfer',
        categoryId: fallbackCatId,
        walletId: fromWalletId,
        date: txDate,
        note: note,
      );
      final inTx = TransactionModel(
        id: uuid.v4(),
        userId: userId,
        subcategory: 'Transfer from ${fromWallet.name}',
        amount: amount,
        type: 'transfer',
        categoryId: fallbackCatId,
        walletId: toWalletId,
        date: txDate,
        note: note,
      );

      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.updateWalletBalance(fromWalletId, userId, -amount);
      await syncRepo.updateWalletBalance(toWalletId, userId, amount);
      await syncRepo.saveTransaction(outTx);
      await syncRepo.saveTransaction(inTx);

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
  return all
      .where((t) => t.isExpense)
      .fold<double>(0.0, (s, t) => s + t.amount);
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
      if (!t.subcategory.toLowerCase().contains(search.toLowerCase()))
        return false;
    }
    if (month != null) {
      final d = DateTime.parse(t.date);
      if (d.year != month.year || d.month != month.month) return false;
    }
    return true;
  }).toList();
}

@riverpod
Future<double> currentMonthIncome(Ref ref) async {
  final all = await ref.watch(transactionsProvider.future);
  final selectedWalletId = ref.watch(selectedWalletIdProvider);
  final now = DateTime.now();
  return all
      .where((t) {
        if (!t.isIncome) return false;
        if (selectedWalletId != null && t.walletId != selectedWalletId)
          return false;
        final d = DateTime.tryParse(t.date);
        if (d == null) return false;
        return d.year == now.year && d.month == now.month;
      })
      .fold<double>(0.0, (s, t) => s + t.amount);
}

@riverpod
Future<double> currentMonthExpense(Ref ref) async {
  final all = await ref.watch(transactionsProvider.future);
  final selectedWalletId = ref.watch(selectedWalletIdProvider);
  final now = DateTime.now();
  return all
      .where((t) {
        if (!t.isExpense) return false;
        if (selectedWalletId != null && t.walletId != selectedWalletId)
          return false;
        final d = DateTime.tryParse(t.date);
        if (d == null) return false;
        return d.year == now.year && d.month == now.month;
      })
      .fold<double>(0.0, (s, t) => s + t.amount);
}

@riverpod
Future<double> dashboardDisplayBalance(Ref ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  return wallets.isNotEmpty ? wallets.first.balance : 0.0;
}
