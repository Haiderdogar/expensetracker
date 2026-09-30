import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/category_utils.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/formatters.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import 'auth_provider.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_provider.dart';

part 'budget_provider.g.dart';

@Riverpod(keepAlive: true)
class Budgets extends _$Budgets {
  @override
  Future<List<BudgetModel>> build() => _fetchAll();

  Future<List<BudgetModel>> _fetchAll() async {
    try {
      ref.watch(localDataEpochProvider);
      final userId = ref.watch(currentUserIdProvider);
      final walletId = ref.watch(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      return await syncRepo.getBudgets(userId, walletId: walletId);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAll);
  }

  Future<void> upsert(BudgetModel budget) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final walletId = ref.read(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      final budgetToSave = budget.copyWith(
        userId: userId,
        walletId: walletId,
        isSynced: false,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      // ── Step 1: Write to SQLite instantly.
      await syncRepo.saveBudgetLocalOnly(budgetToSave);

      // ── Step 2: Optimistic UI update.
      final current = state.value ?? [];
      final exists = current.any((b) => b.id == budgetToSave.id);
      if (exists) {
        state = AsyncData(
          current.map((b) => b.id == budgetToSave.id ? budgetToSave : b).toList(),
        );
      } else {
        state = AsyncData([budgetToSave, ...current]);
      }

      // ── Step 3: Push to Firestore in the background.
      unawaited(syncRepo.pushBudgetRemote(budgetToSave));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);

      // Find from current state to get walletId for remote push.
      final current = state.value ?? [];
      final old = current.where((b) => b.id == id).firstOrNull;
      if (old == null) return;

      // ── Step 1: Soft-delete locally (instant).
      await syncRepo.deleteBudgetLocalOnly(id, userId);

      // ── Step 2: Optimistic UI update — remove immediately.
      state = AsyncData(current.where((b) => b.id != id).toList());

      // ── Step 3: Push soft-delete to Firestore in the background.
      unawaited(syncRepo.pushDeleteRemote(
        table: 'budgets',
        userId: userId,
        id: id,
        walletId: old.walletId,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<BudgetModel> create({
    required String categoryId,
    required double amount,
    DateTime? month,
  }) async {
    final m = month ?? DateTime.now();
    final monthYear = Formatters.monthYear(m);
    final existingBudgets = state.value ?? await future;
    if (existingBudgets.any(
      (budget) =>
          budget.categoryId == categoryId && budget.monthYear == monthYear,
    )) {
      throw AppException(
        'A budget already exists for this category and month.',
      );
    }

    const uuid = Uuid();
    final userId = ref.read(currentUserIdProvider);
    final walletId = ref.read(activeWalletIdProvider);
    final budget = BudgetModel(
      id: uuid.v4(),
      userId: userId,
      walletId: walletId ?? '',
      categoryId: categoryId,
      amount: amount,
      monthYear: monthYear,
    );
    await upsert(budget);
    return budget;
  }

  Future<int> copyFromPreviousMonth(DateTime targetMonth) async {
    final prevMonth = DateTime(targetMonth.year, targetMonth.month - 1, 1);
    final prevMonthKey = Formatters.monthYear(prevMonth);
    final targetMonthKey = Formatters.monthYear(targetMonth);

    final allBudgets = state.value ?? await future;
    final prevBudgets = allBudgets
        .where((b) => b.monthYear == prevMonthKey)
        .toList();
    if (prevBudgets.isEmpty) return 0;

    final existingTargetCategoryIds = allBudgets
        .where((b) => b.monthYear == targetMonthKey)
        .map((b) => b.categoryId)
        .toSet();

    int copied = 0;
    for (final b in prevBudgets) {
      if (!existingTargetCategoryIds.contains(b.categoryId)) {
        await create(
          categoryId: b.categoryId,
          amount: b.amount,
          month: targetMonth,
        );
        copied++;
      }
    }
    return copied;
  }
}

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    this.category,
    String? categoryName,
  }) : _fallbackCategoryName = categoryName ?? 'Unknown';

  final BudgetModel budget;
  final double spent;
  final CategoryModel? category;
  final String _fallbackCategoryName;

  String get categoryName => category?.name ?? _fallbackCategoryName;

  Color get categoryColor => category != null
      ? categoryColorFromHex(category!.color)
      : const Color(0xFF94A3B8);
  IconData get categoryIcon => category != null
      ? categoryIconFromName(category!.icon)
      : Icons.category_outlined;

  double get progress => budget.amount > 0 ? spent / budget.amount : 0.0;
  double get remaining => budget.amount - spent;
  bool get isOverBudget => spent > budget.amount;
  bool get isNearLimit => !isOverBudget && (progress >= 0.80);
}

@riverpod
Future<List<BudgetProgress>> monthBudgetProgress(
  Ref ref,
  DateTime month,
) async {
  final monthKey = Formatters.monthYear(month);
  final budgets = await ref.watch(budgetsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);

  final monthBudgets = budgets.where((b) => b.monthYear == monthKey).toList();

  return monthBudgets.map((budget) {
    final spent = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.categoryId == budget.categoryId &&
              Formatters.monthYear(DateTime.parse(t.date)) == monthKey,
        )
        .fold(0.0, (s, t) => s + t.amount);

    final category = categories
        .where((c) => c.id == budget.categoryId)
        .firstOrNull;

    return BudgetProgress(
      budget: budget,
      spent: spent,
      category: category,
      categoryName: category?.name ?? 'Unknown',
    );
  }).toList();
}

@riverpod
Future<List<BudgetProgress>> currentMonthBudgetProgress(Ref ref) async {
  return ref.watch(monthBudgetProgressProvider(DateTime.now()).future);
}
