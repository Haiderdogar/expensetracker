import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/subcategory_model.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

final subcategoriesProvider =
    FutureProvider.family<List<SubcategoryModel>, String>((ref, categoryId) async {
  try {
    final db = await ref.watch(databaseProvider.future);
    final rows = await db.query(
      DatabaseTables.subcategories,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(SubcategoryModel.fromMap).toList();
  } catch (e) {
    throw ErrorHandler.from(e);
  }
});

Future<SubcategoryModel> addSubcategory(
  WidgetRef ref, {
  required String categoryId,
  required String name,
}) async {
  try {
    final subcategory = SubcategoryModel(
      id: const Uuid().v4(),
      categoryId: categoryId,
      name: name.trim(),
    );
    final db = await ref.read(databaseProvider.future);
    await db.insert(DatabaseTables.subcategories, subcategory.toMap());
    ref.invalidate(subcategoriesProvider(categoryId));
    return subcategory;
  } catch (e) {
    throw ErrorHandler.from(e);
  }
}

Future<void> updateSubcategory(
  WidgetRef ref, {
  required SubcategoryModel subcategory,
  required String name,
}) async {
  try {
    final updatedName = name.trim();
    final db = await ref.read(databaseProvider.future);
    await db.transaction((transaction) async {
      await transaction.update(
        DatabaseTables.subcategories,
        {'name': updatedName},
        where: 'id = ?',
        whereArgs: [subcategory.id],
      );
      await transaction.update(
        DatabaseTables.transactions,
        {'subcategory': updatedName},
        where: 'category_id = ? AND subcategory = ?',
        whereArgs: [subcategory.categoryId, subcategory.name],
      );
    });
    ref.invalidate(subcategoriesProvider(subcategory.categoryId));
    ref.invalidate(transactionsProvider);
  } catch (e) {
    throw ErrorHandler.from(e);
  }
}

Future<void> deleteSubcategory(WidgetRef ref, SubcategoryModel subcategory) async {
  try {
    final db = await ref.read(databaseProvider.future);
    final remaining = await db.query(
      DatabaseTables.subcategories,
      columns: ['id'],
      where: 'category_id = ?',
      whereArgs: [subcategory.categoryId],
      limit: 2,
    );
    if (remaining.length <= 1) {
      throw AppException('Every category must have at least one subcategory.');
    }
    await db.delete(
      DatabaseTables.subcategories,
      where: 'id = ?',
      whereArgs: [subcategory.id],
    );
    ref.invalidate(subcategoriesProvider(subcategory.categoryId));
  } catch (e) {
    throw ErrorHandler.from(e);
  }
}
