import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../models/category_model.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/formatters.dart';
import '../models/budget_model.dart';
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
}

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.categoryName,
  });

  final BudgetModel budget;
  final double spent;
  final String categoryName;

  double get progress => budget.amount > 0 ? spent / budget.amount : 0;
  double get remaining => budget.amount - spent;
}

@riverpod
Future<List<BudgetProgress>> currentMonthBudgetProgress(
  Ref ref,
) async {
  final monthKey = Formatters.monthYear(DateTime.now());
  final budgets = await ref.watch(budgetsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);

  final monthBudgets = budgets.where((b) => b.monthYear == monthKey);

  return monthBudgets.map((budget) {
    final spent = transactions
        .where((t) =>
            t.isExpense &&
            t.categoryId == budget.categoryId &&
            Formatters.monthYear(DateTime.parse(t.date)) == monthKey)
        .fold(0.0, (s, t) => s + t.amount);

    // Resolve category name safely. If category has been deleted, fall back to 'Unknown'.
    CategoryModel? category;
    try {
      category = categories.firstWhere((c) => c.id == budget.categoryId);
    } catch (_) {
      category = null;
    }

    return BudgetProgress(
      budget: budget,
      spent: spent,
      categoryName: category?.name ?? 'Unknown',
    );
  }).toList();
}
