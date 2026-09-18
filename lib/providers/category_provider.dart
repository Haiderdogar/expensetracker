import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/category_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

part 'category_provider.g.dart';

@Riverpod(keepAlive: true)
class Categories extends _$Categories {
  @override
  Future<List<CategoryModel>> build() => _fetchAll();

  Future<List<CategoryModel>> _fetchAll() async {
    try {
      ref.watch(localDataEpochProvider);
      final userId = ref.watch(currentUserIdProvider);
      final walletId = ref.watch(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      return await syncRepo.getCategories(userId, walletId: walletId);
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
      final userId = ref.read(currentUserIdProvider);
      final walletId = ref.read(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      final catToSave = category.copyWith(userId: userId, walletId: walletId);
      await syncRepo.saveCategory(catToSave);

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
    final userId = ref.read(currentUserIdProvider);
    final walletId = ref.read(activeWalletIdProvider);
    final category = CategoryModel(
      id: uuid.v4(),
      userId: userId,
      walletId: walletId ?? '',
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
      final userId = ref.read(currentUserIdProvider);
      final transactions = await db.query(
        DatabaseTables.transactions,
        columns: ['id'],
        where: 'category_id = ? AND user_id = ?',
        whereArgs: [id, userId],
        limit: 1,
      );
      final budgets = await db.query(
        DatabaseTables.budgets,
        columns: ['id'],
        where: 'category_id = ? AND user_id = ?',
        whereArgs: [id, userId],
        limit: 1,
      );
      if (transactions.isNotEmpty || budgets.isNotEmpty) {
        throw AppException(
          'Categories used by transactions or budgets cannot be deleted.',
        );
      }

      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.deleteCategory(id, userId);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final walletId = ref.read(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.saveCategory(
        category.copyWith(userId: userId, walletId: walletId),
      );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}

@riverpod
Future<List<CategoryModel>> incomeCategories(Ref ref) async {
  return ref
      .watch(categoriesProvider.future)
      .then((list) => list.where((c) => c.isIncome).toList());
}

@riverpod
Future<List<CategoryModel>> expenseCategories(Ref ref) async {
  return ref
      .watch(categoriesProvider.future)
      .then((list) => list.where((c) => c.isExpense).toList());
}

@riverpod
Future<List<CategoryModel>> usedCategories(Ref ref, String? type) async {
  final all = await ref.watch(categoriesProvider.future);
  final txs = await ref.watch(transactionsProvider.future);
  final usedIds = txs.map((t) => t.categoryId).toSet();
  return all
      .where((c) => usedIds.contains(c.id) && (type == null || c.type == type))
      .toList();
}
