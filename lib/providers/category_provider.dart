import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/category_model.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

part 'category_provider.g.dart';

@Riverpod(keepAlive: true)
class Categories extends _$Categories {
  @override
  Future<List<CategoryModel>> build() => _fetchAll();

  Future<List<CategoryModel>> _fetchAll() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final rows = await db.query(
        DatabaseTables.categories,
        orderBy: 'name ASC',
      );
      return rows.map(CategoryModel.fromMap).toList();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAll);
  }

  Future<List<CategoryModel>> byType(String type) async {
    final all = await future;
    return all.where((c) => c.type == type).toList();
  }

  Future<void> add(CategoryModel category) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.insert(DatabaseTables.categories, category.toMap());
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<CategoryModel> create({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    const uuid = Uuid();
    final category = CategoryModel(
      id: uuid.v4(),
      name: name,
      type: type,
      icon: icon,
      color: color,
    );
    await add(category);
    return category;
  }

  Future<void> delete(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.delete(DatabaseTables.categories, where: 'id = ?', whereArgs: [id]);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}

@riverpod
Future<List<CategoryModel>> incomeCategories(Ref ref) async {
  return ref.watch(categoriesProvider.future).then(
        (list) => list.where((c) => c.isIncome).toList(),
      );
}

@riverpod
Future<List<CategoryModel>> expenseCategories(Ref ref) async {
  return ref.watch(categoriesProvider.future).then(
        (list) => list.where((c) => c.isExpense).toList(),
      );
}

// Categories that are actually used in transactions. Returns categories of the
// given type that have at least one transaction referencing them.
final usedCategoriesProvider = FutureProvider.family<List<CategoryModel>, String?>((ref, type) async {
  final all = await ref.watch(categoriesProvider.future);
  final txs = await ref.watch(transactionsProvider.future);
  final usedIds = txs.map((t) => t.categoryId).toSet();
  return all.where((c) => usedIds.contains(c.id) && (type == null || c.type == type)).toList();
});
