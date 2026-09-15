import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../models/note_model.dart';
import '../../models/subcategory_model.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';

/// Local-first persistence with WhatsApp-style queued Cloud Firestore sync.
///
/// UI always reads SQLite. Mutations write locally first (`is_synced = 0`),
/// then push to Firestore when online and mark `is_synced = 1`.
class SyncRepository {
  SyncRepository({
    DatabaseHelper? dbHelper,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivity = connectivity ?? Connectivity();

  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  void initConnectivityListener(String Function() getUserId) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        final userId = getUserId();
        if (userId.isNotEmpty && userId != 'default_user') {
          unawaited(syncPending(userId));
        }
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  CollectionReference<Map<String, dynamic>> _col(String userId, String table) {
    return _firestore.collection('users').doc(userId).collection(table);
  }

  Future<void> _upsertLocalThenPush({
    required String table,
    required String userId,
    required String id,
    required Map<String, dynamic> sqliteRow,
    required Map<String, dynamic> firestoreData,
  }) async {
    _validateUserRecord(userId, sqliteRow['user_id'], firestoreData['userId']);
    final db = await _dbHelper.database;
    await db.insert(
      table,
      sqliteRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (!await isOnline()) return;
    try {
      await _col(userId, table).doc(id).set(firestoreData);
      await db.update(
        table,
        {'is_synced': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } catch (e) {
      debugPrint('[SyncRepository] Immediate push failed ($table/$id): $e');
    }
  }

  Future<void> _deleteLocalThenPush({
    required String table,
    required String userId,
    required String id,
  }) async {
    _validateUserId(userId);
    final db = await _dbHelper.database;
    await db.delete(
      table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    await db.insert(DatabaseTables.syncQueue, {
      'id': const Uuid().v4(),
      'table_name': table,
      'record_id': id,
      'operation': 'delete',
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (!await isOnline()) return;
    try {
      await _col(userId, table).doc(id).delete();
      await db.delete(
        DatabaseTables.syncQueue,
        where: 'table_name = ? AND record_id = ? AND user_id = ?',
        whereArgs: [table, id, userId],
      );
    } catch (e) {
      debugPrint('[SyncRepository] Immediate delete failed ($table/$id): $e');
    }
  }

  Future<List<Map<String, dynamic>>> _queryUser(
    String table,
    String userId, {
    String? extraWhere,
    List<Object?> extraArgs = const [],
    String? orderBy,
  }) async {
    _validateUserId(userId);
    final db = await _dbHelper.database;
    final where = extraWhere == null
        ? 'user_id = ?'
        : 'user_id = ? AND $extraWhere';
    final whereArgs = [userId, ...extraArgs];
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  /// Prevents an accidental cross-account model from ever being persisted or
  /// uploaded. Firestore rules provide the server-side enforcement; this is a
  /// deliberately redundant client-side guard.
  void _validateUserRecord(String userId, Object? localUserId, Object? remoteUserId) {
    _validateUserId(userId);
    if (localUserId != userId || remoteUserId != userId) {
      throw ArgumentError.value(userId, 'userId', 'Record belongs to another user');
    }
  }

  void _validateUserId(String userId) {
    if (userId.isEmpty || userId == 'default_user') {
      throw ArgumentError.value(userId, 'userId', 'An authenticated user is required');
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final rows = await _queryUser(
      DatabaseTables.transactions,
      userId,
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> saveTransaction(TransactionModel tx) async {
    final model = tx.copyWith(
      isSynced: false,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _upsertLocalThenPush(
      table: DatabaseTables.transactions,
      userId: model.userId,
      id: model.id,
      sqliteRow: model.toMap(),
      firestoreData: model.toFirestore(),
    );
  }

  Future<void> deleteTransaction(String id, String userId) {
    return _deleteLocalThenPush(
      table: DatabaseTables.transactions,
      userId: userId,
      id: id,
    );
  }

  // ── Wallets ───────────────────────────────────────────────────────────────

  Future<List<WalletModel>> getWallets(String userId) async {
    final rows = await _queryUser(
      DatabaseTables.wallets,
      userId,
      orderBy: 'name ASC',
    );
    return rows.map(WalletModel.fromMap).toList();
  }

  Future<void> saveWallet(WalletModel wallet) async {
    final model = wallet.copyWith(
      isSynced: false,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _upsertLocalThenPush(
      table: DatabaseTables.wallets,
      userId: model.userId,
      id: model.id,
      sqliteRow: model.toMap(),
      firestoreData: model.toFirestore(),
    );
  }

  Future<void> updateWalletBalance(
    String walletId,
    String userId,
    double delta,
  ) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseTables.wallets} SET balance = balance + ?, is_synced = 0, updated_at = ? WHERE id = ? AND user_id = ?',
      [delta, DateTime.now().toUtc().toIso8601String(), walletId, userId],
    );

    if (!await isOnline()) return;
    try {
      final rows = await db.query(
        DatabaseTables.wallets,
        where: 'id = ? AND user_id = ?',
        whereArgs: [walletId, userId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final wallet = WalletModel.fromMap(rows.first);
      await _col(userId, DatabaseTables.wallets).doc(walletId).set(wallet.toFirestore());
      await db.update(
        DatabaseTables.wallets,
        {'is_synced': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: [walletId, userId],
      );
    } catch (e) {
      debugPrint('[SyncRepository] Wallet balance push failed: $e');
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories(String userId) async {
    final rows = await _queryUser(
      DatabaseTables.categories,
      userId,
      orderBy: 'name ASC',
    );
    // Defaults may have been seeded locally before the same defaults were
    // pulled from Firestore on a second installation. Their IDs differ, but
    // they represent the same category. The UI must never expose those as
    // duplicate choices.
    return _uniqueBy(
      rows.map(CategoryModel.fromMap),
      (category) => '${category.type}:${_normalizedName(category.name)}',
    );
  }

  Future<void> saveCategory(CategoryModel category) async {
    final model = category.copyWith(
      isSynced: false,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _upsertLocalThenPush(
      table: DatabaseTables.categories,
      userId: model.userId,
      id: model.id,
      sqliteRow: model.toMap(),
      firestoreData: model.toFirestore(),
    );
  }

  Future<void> deleteCategory(String id, String userId) {
    return _deleteLocalThenPush(
      table: DatabaseTables.categories,
      userId: userId,
      id: id,
    );
  }

  Future<List<SubcategoryModel>> getSubcategories(
    String userId, [
    String? categoryId,
  ]) async {
    final rows = await _queryUser(
      DatabaseTables.subcategories,
      userId,
      extraWhere: categoryId == null ? null : 'category_id = ?',
      extraArgs: categoryId == null ? const [] : [categoryId],
      orderBy: 'name ASC',
    );
    // A subcategory is selected by name in the transaction form, so duplicate
    // local/remote IDs with the same normalized name would otherwise render
    // the same option more than once.
    return _uniqueBy(
      rows.map(SubcategoryModel.fromMap),
      (subcategory) => _normalizedName(subcategory.name),
    );
  }

  List<T> _uniqueBy<T>(
    Iterable<T> values,
    String Function(T value) keyOf,
  ) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (seen.add(keyOf(value))) value,
    ];
  }

  String _normalizedName(String value) => value.trim().toLowerCase();

  Future<void> saveSubcategory(SubcategoryModel sub) async {
    final model = sub.copyWith(
      isSynced: false,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _upsertLocalThenPush(
      table: DatabaseTables.subcategories,
      userId: model.userId,
      id: model.id,
      sqliteRow: model.toMap(),
      firestoreData: model.toFirestore(),
    );
  }

  Future<void> deleteSubcategory(String id, String userId) {
    return _deleteLocalThenPush(
      table: DatabaseTables.subcategories,
      userId: userId,
      id: id,
    );
  }

  Future<void> renameSubcategory({
    required SubcategoryModel subcategory,
    required String newName,
  }) async {
    final updated = subcategory.copyWith(
      name: newName.trim(),
      isSynced: false,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await saveSubcategory(updated);

    final db = await _dbHelper.database;
    await db.update(
      DatabaseTables.transactions,
      {
        'subcategory': updated.name,
        'is_synced': 0,
        'updated_at': updated.updatedAt,
      },
      where: 'category_id = ? AND subcategory = ? AND user_id = ?',
      whereArgs: [subcategory.categoryId, subcategory.name, subcategory.userId],
    );

    if (await isOnline()) {
      await syncPending(subcategory.userId);
    }
  }

  // ── Budgets ───────────────────────────────────────────────────────────────

  Future<List<BudgetModel>> getBudgets(String userId) async {
    final rows = await _queryUser(DatabaseTables.budgets, userId);
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final model = budget.copyWith(
      isSynced: false,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _upsertLocalThenPush(
      table: DatabaseTables.budgets,
      userId: model.userId,
      id: model.id,
      sqliteRow: model.toMap(),
      firestoreData: model.toFirestore(),
    );
  }

  Future<void> deleteBudget(String id, String userId) {
    return _deleteLocalThenPush(
      table: DatabaseTables.budgets,
      userId: userId,
      id: id,
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<List<NoteModel>> getNotes(String userId) async {
    final rows = await _queryUser(
      DatabaseTables.notes,
      userId,
      orderBy: 'updated_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<NoteModel?> getNote(String id, String userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.notes,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NoteModel.fromMap(rows.first);
  }

  Future<void> saveNote(NoteModel note) async {
    final model = note.copyWith(isSynced: false);
    await _upsertLocalThenPush(
      table: DatabaseTables.notes,
      userId: model.userId,
      id: model.id,
      sqliteRow: model.toMap(),
      firestoreData: model.toFirestore(),
    );
  }

  Future<void> deleteNote(String id, String userId) {
    return _deleteLocalThenPush(
      table: DatabaseTables.notes,
      userId: userId,
      id: id,
    );
  }

  // ── Sync engine ───────────────────────────────────────────────────────────

  Future<void> syncPending(String userId) async {
    if (_isSyncing) return;
    if (!await isOnline()) return;
    if (userId.isEmpty || userId == 'default_user') return;

    _isSyncing = true;
    try {
      final db = await _dbHelper.database;

      final queuedDeletes = await db.query(
        DatabaseTables.syncQueue,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      for (final row in queuedDeletes) {
        final table = row['table_name'] as String;
        final recordId = row['record_id'] as String;
        final qId = row['id'] as String;
        try {
          await _col(userId, table).doc(recordId).delete();
          await db.delete(
            DatabaseTables.syncQueue,
            where: 'id = ?',
            whereArgs: [qId],
          );
        } catch (e) {
          debugPrint('[SyncRepository] Queued delete failed: $e');
        }
      }

      await _pushUnsynced(
        db,
        userId,
        DatabaseTables.categories,
        (row) => CategoryModel.fromMap(row).toFirestore(),
      );
      await _pushUnsynced(
        db,
        userId,
        DatabaseTables.subcategories,
        (row) => SubcategoryModel.fromMap(row).toFirestore(),
      );
      await _pushUnsynced(
        db,
        userId,
        DatabaseTables.wallets,
        (row) => WalletModel.fromMap(row).toFirestore(),
      );
      await _pushUnsynced(
        db,
        userId,
        DatabaseTables.transactions,
        (row) => TransactionModel.fromMap(row).toFirestore(),
      );
      await _pushUnsynced(
        db,
        userId,
        DatabaseTables.budgets,
        (row) => BudgetModel.fromMap(row).toFirestore(),
      );
      await _pushUnsynced(
        db,
        userId,
        DatabaseTables.notes,
        (row) => NoteModel.fromMap(row).toFirestore(),
      );
    } catch (e) {
      debugPrint('[SyncRepository] Sync pending failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushUnsynced(
    Database db,
    String userId,
    String table,
    Map<String, dynamic> Function(Map<String, dynamic> row) toFirestore,
  ) async {
    final rows = await db.query(
      table,
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      try {
        await _col(userId, table).doc(id).set(toFirestore(row));
        await db.update(
          table,
          {'is_synced': 1},
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );
      } catch (e) {
        debugPrint('[SyncRepository] Push $table/$id failed: $e');
      }
    }
  }

  /// Pull remote documents into SQLite using last-write-wins, without
  /// overwriting newer unsynced local edits.
  Future<void> reconcileWithRemote(String userId) async {
    if (!await isOnline()) return;
    if (userId.isEmpty || userId == 'default_user') return;

    try {
      await _mergeRemote(
        userId,
        DatabaseTables.categories,
        (data, id) => CategoryModel.fromFirestore(data, id).toMap(),
      );
      await _mergeRemote(
        userId,
        DatabaseTables.subcategories,
        (data, id) => SubcategoryModel.fromFirestore(data, id).toMap(),
      );
      await _mergeRemote(
        userId,
        DatabaseTables.wallets,
        (data, id) => WalletModel.fromFirestore(data, id).toMap(),
      );
      await _mergeRemote(
        userId,
        DatabaseTables.transactions,
        (data, id) => TransactionModel.fromFirestore(data, id).toMap(),
      );
      await _mergeRemote(
        userId,
        DatabaseTables.budgets,
        (data, id) => BudgetModel.fromFirestore(data, id).toMap(),
      );
      await _mergeRemote(
        userId,
        DatabaseTables.notes,
        (data, id) => NoteModel.fromFirestore(data, id).toMap(),
      );

      await syncPending(userId);
    } catch (e) {
      debugPrint('[SyncRepository] Reconcile with remote failed: $e');
    }
  }

  Future<void> _mergeRemote(
    String userId,
    String table,
    Map<String, dynamic> Function(Map<String, dynamic> data, String id) toSqlite,
  ) async {
    final snap = await _col(userId, table).get();
    final db = await _dbHelper.database;

    for (final doc in snap.docs) {
      // Documents are stored under the authenticated user's path and carry the
      // userId field as defence in depth. Ignore malformed/cross-user records.
      if (doc.data()['userId'] != userId) continue;
      final remoteRow = toSqlite(doc.data(), doc.id);
      final existing = await db.query(
        table,
        where: 'id = ? AND user_id = ?',
        whereArgs: [doc.id, userId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final local = existing.first;
        final localSynced = (local['is_synced'] as int?) == 1;
        final localUpdated = DateTime.tryParse(
              (local['updated_at'] as String?) ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final remoteUpdated = DateTime.tryParse(
              (remoteRow['updated_at'] as String?) ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        if (!localSynced && !remoteUpdated.isAfter(localUpdated)) {
          continue;
        }
        if (localSynced && localUpdated.isAfter(remoteUpdated)) {
          continue;
        }
      }

      await db.insert(
        table,
        remoteRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
