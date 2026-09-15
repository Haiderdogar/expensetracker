import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/subcategory_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

part 'subcategory_provider.g.dart';

@riverpod
Future<List<SubcategoryModel>> subcategories(Ref ref, String categoryId) async {
  try {
    ref.watch(localDataEpochProvider);
    final userId = ref.watch(currentUserIdProvider);
    final syncRepo = ref.read(syncRepositoryProvider);
    return await syncRepo.getSubcategories(userId, categoryId);
  } catch (e) {
    throw ErrorHandler.from(e);
  }
}

Future<SubcategoryModel> addSubcategory(
  WidgetRef ref, {
  required String categoryId,
  required String name,
}) async {
  try {
    final userId = ref.read(currentUserIdProvider);
    final subcategory = SubcategoryModel(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: categoryId,
      name: name.trim(),
    );
    final syncRepo = ref.read(syncRepositoryProvider);
    await syncRepo.saveSubcategory(subcategory);
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
    final userId = ref.read(currentUserIdProvider);
    final syncRepo = ref.read(syncRepositoryProvider);
    await syncRepo.renameSubcategory(
      subcategory: subcategory.copyWith(userId: userId),
      newName: name,
    );
    ref.invalidate(subcategoriesProvider(subcategory.categoryId));
    ref.invalidate(transactionsProvider);
  } catch (e) {
    throw ErrorHandler.from(e);
  }
}

Future<void> deleteSubcategory(WidgetRef ref, SubcategoryModel subcategory) async {
  try {
    final db = await ref.read(databaseProvider.future);
    final userId = ref.read(currentUserIdProvider);
    final remaining = await db.query(
      DatabaseTables.subcategories,
      columns: ['id'],
      where: 'category_id = ? AND user_id = ?',
      whereArgs: [subcategory.categoryId, userId],
      limit: 2,
    );
    if (remaining.length <= 1) {
      throw AppException('Every category must have at least one subcategory.');
    }
    final syncRepo = ref.read(syncRepositoryProvider);
    await syncRepo.deleteSubcategory(subcategory.id, userId);
    ref.invalidate(subcategoriesProvider(subcategory.categoryId));
  } catch (e) {
    throw ErrorHandler.from(e);
  }
}
