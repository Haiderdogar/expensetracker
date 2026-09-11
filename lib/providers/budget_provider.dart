import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/category_utils.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/formatters.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

part 'budget_provider.g.dart';

@Riverpod(keepAlive: true)
class Budgets extends _$Budgets {
  @override
  Future<List<BudgetModel>> build() => _fetchAll();

  Future<List<BudgetModel>> _fetchAll() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final rows = await db.query(DatabaseTables.budgets);
      return rows.map(BudgetModel.fromMap).toList();
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
      final db = await ref.read(databaseProvider.future);
      await db.insert(
        DatabaseTables.budgets,
        budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.delete(
        DatabaseTables.budgets,
        where: 'id = ?',
        whereArgs: [id],
      );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<BudgetModel> create({
    required String categoryId,
    required double amount,
    DateTime? month,
  }) async {
    const uuid = Uuid();
    final m = month ?? DateTime.now();
    final budget = BudgetModel(
      id: uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      monthYear: Formatters.monthYear(m),
    );
    await upsert(budget);
    return budget;
  }

  Future<int> copyFromPreviousMonth(DateTime targetMonth) async {
    final prevMonth = DateTime(targetMonth.year, targetMonth.month - 1, 1);
    final prevMonthKey = Formatters.monthYear(prevMonth);
    final targetMonthKey = Formatters.monthYear(targetMonth);

    final allBudgets = await ref.read(budgetsProvider.future);
    final prevBudgets =
        allBudgets.where((b) => b.monthYear == prevMonthKey).toList();
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

final monthBudgetProgressProvider =
    FutureProvider.family<List<BudgetProgress>, DateTime>((ref, month) async {
  final monthKey = Formatters.monthYear(month);
  final budgets = await ref.watch(budgetsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);

  final monthBudgets = budgets.where((b) => b.monthYear == monthKey).toList();

  return monthBudgets.map((budget) {
    final spent = transactions
        .where((t) =>
            t.isExpense &&
            t.categoryId == budget.categoryId &&
            Formatters.monthYear(DateTime.parse(t.date)) == monthKey)
        .fold(0.0, (s, t) => s + t.amount);

    final category =
        categories.where((c) => c.id == budget.categoryId).firstOrNull;

    return BudgetProgress(
      budget: budget,
      spent: spent,
      category: category,
      categoryName: category?.name ?? 'Unknown',
    );
  }).toList();
});

@riverpod
Future<List<BudgetProgress>> currentMonthBudgetProgress(Ref ref) async {
  return ref.watch(monthBudgetProgressProvider(DateTime.now()).future);
}
