import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/category_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_provider.dart';

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
      await ref
          .read(databaseHelperProvider)
          .ensureBuiltInCategories(userId);
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
    if (walletId == null || walletId.isEmpty) {
      throw AppException('Create or select a wallet before adding a category.');
    }
    final category = CategoryModel(
      id: uuid.v4(),
      userId: userId,
      walletId: walletId,
      name: name,
      type: type,
      icon: icon,
      color: color,
    );
    await add(category);
    return category;
  }

  Future<bool> delete(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final userId = ref.read(currentUserIdProvider);
      final categories = await future;
      final category = categories.firstWhere((item) => item.id == id);
      if (category.isBuiltIn) {
        throw AppException('Built-in categories can be hidden, not deleted.');
      }
      final syncRepo = ref.read(syncRepositoryProvider);
      final isRemoteStateKnown = await syncRepo.reconcileWithRemote(userId);
      final transactions = await db.query(
        DatabaseTables.transactions,
        columns: ['id'],
        where: 'category_id = ? AND user_id = ? AND wallet_id = ?',
        whereArgs: [id, userId, category.walletId],
        limit: 1,
      );
      final budgets = await db.query(
        DatabaseTables.budgets,
        columns: ['id'],
        where: 'category_id = ? AND user_id = ? AND wallet_id = ?',
        whereArgs: [id, userId, category.walletId],
        limit: 1,
      );
      final remoteReferences = isRemoteStateKnown
          ? await syncRepo.hasRemoteCategoryReferences(
              id,
              userId,
              category.walletId,
            )
          : true;

      final hasReferences =
          remoteReferences || transactions.isNotEmpty || budgets.isNotEmpty;
      if (hasReferences) {
        await syncRepo.saveCategory(category.copyWith(isArchived: true));
      } else {
        await syncRepo.deleteCategory(id, userId);
      }
      await refresh();
      return hasReferences;
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      if (category.isBuiltIn) {
        throw AppException('Built-in categories cannot be edited.');
      }
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

  Future<void> setBuiltInHidden(String id, {required bool hidden}) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final db = await ref.read(databaseProvider.future);
      final result = await db.update(
        DatabaseTables.categories,
        {'is_hidden': hidden ? 1 : 0},
        where: 'id = ? AND user_id = ? AND is_builtin = 1',
        whereArgs: [id, userId],
      );
      if (result != 1) {
        throw StateError('The built-in category could not be updated.');
      }
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
      .then(
        (list) => list
            .where((c) => c.isIncome && !c.isHidden && !c.isArchived)
            .toList(),
      );
}

@riverpod
Future<List<CategoryModel>> expenseCategories(Ref ref) async {
  return ref
      .watch(categoriesProvider.future)
      .then(
        (list) => list
            .where((c) => c.isExpense && !c.isHidden && !c.isArchived)
            .toList(),
      );
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
