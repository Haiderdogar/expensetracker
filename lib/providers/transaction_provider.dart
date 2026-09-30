import 'dart:async';

import 'package:expensetracker/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/error_handler.dart';
import '../models/transaction_model.dart';
import 'auth_provider.dart';
import 'category_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_provider.dart';

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
      final txToSave = transaction.copyWith(
        userId: userId,
        isSynced: false,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      // ── Step 1: Write to SQLite and update the manifest entry
      //   (fast local DB write — this is what the user waits for).
      await syncRepo.saveTransactionLocalOnly(txToSave);

      // ── Step 2: Optimistic UI update — splice directly into the
      //   current list so the screen updates instantly with no re-query.
      final current = state.value ?? [];
      final updated = [txToSave, ...current];
      state = AsyncData(updated);

      // ── Step 3: Update wallet balance locally and in UI.
      final delta = transaction.isIncome ? transaction.amount : -transaction.amount;
      unawaited(
        ref.read(walletsProvider.notifier).updateBalance(transaction.walletId, delta),
      );

      // ── Step 4: Push to Firestore in the background — user never waits.
      unawaited(syncRepo.pushTransactionRemote(txToSave));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final walletId = ref.read(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);

      // Find the old version from current state (no extra DB query needed).
      final current = state.value ?? [];
      final old = current.where((t) => t.id == transaction.id).firstOrNull;
      if (old == null) throw ErrorHandler.from(Exception('Transaction not found'));

      final txToSave = transaction.copyWith(
        userId: userId,
        walletId: walletId ?? transaction.walletId,
        isSynced: false,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      // ── Step 1: Write to SQLite instantly.
      await syncRepo.saveTransactionLocalOnly(txToSave);

      // ── Step 2: Optimistic UI update — replace the old item in-place.
      final updated = current.map((t) => t.id == txToSave.id ? txToSave : t).toList();
      state = AsyncData(updated);

      // ── Step 3: Reverse old balance effect, apply new one — both in background.
      final oldDelta = old.isIncome ? -old.amount : old.amount;
      unawaited(ref.read(walletsProvider.notifier).updateBalance(old.walletId, oldDelta));
      final newDelta = transaction.isIncome ? transaction.amount : -transaction.amount;
      unawaited(ref.read(walletsProvider.notifier).updateBalance(transaction.walletId, newDelta));

      // ── Step 4: Push to Firestore in the background.
      unawaited(syncRepo.pushTransactionRemote(txToSave));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);

      // Find from current state — no extra DB query.
      final current = state.value ?? [];
      final old = current.where((t) => t.id == id).firstOrNull;
      if (old == null) return;

      // ── Step 1: Soft-delete locally (instant).
      await syncRepo.deleteTransactionLocalOnly(id, userId);

      // ── Step 2: Optimistic UI update — remove immediately.
      state = AsyncData(current.where((t) => t.id != id).toList());

      // ── Step 3: Reverse the wallet balance in the background.
      final delta = old.isIncome ? -old.amount : old.amount;
      unawaited(ref.read(walletsProvider.notifier).updateBalance(old.walletId, delta));

      // ── Step 4: Push soft-delete to Firestore in the background.
      unawaited(syncRepo.pushDeleteRemote(
        table: 'transactions',
        userId: userId,
        id: id,
        walletId: old.walletId,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ));
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
    final userId = ref.read(currentUserIdProvider);
    final transaction = TransactionModel(
      id: uuid.v4(),
      userId: userId,
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
      if (!t.title.toLowerCase().contains(search.toLowerCase())) return false;
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
        if (selectedWalletId != null && t.walletId != selectedWalletId) return false;
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
        if (selectedWalletId != null && t.walletId != selectedWalletId) return false;
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
