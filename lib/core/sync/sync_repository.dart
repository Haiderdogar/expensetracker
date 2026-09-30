import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../models/note_model.dart';
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
  bool _syncRequested = false;
  Future<bool>? _initialReconcile;

  static const _initialSyncPrefix = 'initial_remote_sync_';
  static const _syncVersionPrefix = 'sync_version_';

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
        if (userId.isNotEmpty) {
          unawaited(syncPending(userId));
        }
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _syncRequested = false;
  }

  CollectionReference<Map<String, dynamic>> _col(
    String userId,
    String table, {
    String? walletId,
  }) {
    final user = _firestore.collection('users').doc(userId);
    if (table == DatabaseTables.wallets) return user.collection(table);
    if (walletId == null || walletId.isEmpty) {
      throw ArgumentError.value(
        walletId,
        'walletId',
        'A wallet ID is required for wallet-owned data',
      );
    }
    return user
        .collection(DatabaseTables.wallets)
        .doc(walletId)
        .collection(table);
  }

  Future<void> _upsertLocalThenPush({
    required String table,
    required String userId,
    required String id,
    required Map<String, dynamic> sqliteRow,
    required Map<String, dynamic> firestoreData,
    bool waitForRemote = true,
  }) async {
    _validateLocalUserRecord(userId, sqliteRow['user_id']);
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    await db.insert(
      table,
      sqliteRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (!waitForRemote) {
      unawaited(
        _pushUpsert(
          table: table,
          userId: userId,
          id: id,
          sqliteRow: sqliteRow,
          firestoreData: firestoreData,
        ),
      );
      return;
    }
    await _pushUpsert(
      table: table,
      userId: userId,
      id: id,
      sqliteRow: sqliteRow,
      firestoreData: firestoreData,
    );
  }

  Future<void> _pushUpsert({
    required String table,
    required String userId,
    required String id,
    required Map<String, dynamic> sqliteRow,
    required Map<String, dynamic> firestoreData,
  }) async {
    if (!await isOnline()) return;
    try {
      final db = await _dbHelper.database;
      final walletId =
          (firestoreData['walletId'] as String?) ??
          (sqliteRow['wallet_id'] as String?);
      await _col(
        userId,
        table,
        walletId: walletId,
      ).doc(id).set(firestoreData).timeout(const Duration(seconds: 15));
      await db.update(
        table,
        {'is_synced': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      // Update the sync manifest so other devices know exactly what changed.
      unawaited(_updateSyncMeta(userId, table, id, 'u'));
    } catch (e, stackTrace) {
      debugPrint('[SyncRepository] Immediate push failed ($table/$id): $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _deleteLocalThenPush({
    required String table,
    required String userId,
    required String id,
  }) async {
    _validateLocalUserId(userId);
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    final existing = await db.query(
      table,
      columns: ['wallet_id'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    final walletId = existing.isEmpty
        ? null
        : existing.first['wallet_id'] as String?;
    if (existing.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();

    // ── Soft-delete locally ───────────────────────────────────────────────
    // Keep the row but mark it deleted + unsynced so the sync engine can
    // push the deletion to Firestore and broadcast it via the manifest.
    await db.update(
      table,
      {'is_deleted': 1, 'is_synced': 0, 'updated_at': now},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (!await isOnline()) {
      // Queue the delete in sync_queue as a fallback for the next sync pass.
      await db.insert(DatabaseTables.syncQueue, {
        'id': const Uuid().v4(),
        'table_name': table,
        'record_id': id,
        'wallet_id': walletId ?? '',
        'operation': 'delete',
        'user_id': userId,
        'created_at': now,
      });
      return;
    }

    try {
      // Push isDeleted:true to Firestore (do NOT hard-delete the remote doc).
      await _col(
        userId,
        table,
        walletId: walletId,
      ).doc(id).set(
        {'isDeleted': true, 'updatedAt': now},
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 15));
      await db.update(
        table,
        {'is_synced': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      // Tell other devices exactly which record was deleted.
      unawaited(_updateSyncMeta(userId, table, id, 'd'));
    } catch (e, stackTrace) {
      debugPrint('[SyncRepository] Soft-delete push failed ($table/$id): $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> _queryUser(
    String table,
    String userId, {
    String? extraWhere,
    List<Object?> extraArgs = const [],
    String? orderBy,
  }) async {
    _validateLocalUserId(userId);
    final db = await _dbHelper.database;
    // Always exclude soft-deleted rows from every read query.
    final where = extraWhere == null
        ? 'user_id = ? AND is_deleted = 0'
        : 'user_id = ? AND is_deleted = 0 AND $extraWhere';
    final whereArgs = [userId, ...extraArgs];
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  /// Prevents an accidental cross-account model from ever being persisted.
  void _validateLocalUserRecord(String userId, Object? localUserId) {
    _validateLocalUserId(userId);
    if (localUserId != userId) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Record belongs to another user',
      );
    }
  }

  void _validateLocalUserId(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'A valid user ID is required',
      );
    }
  }

  void _validateAuthenticatedUserId(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'An authenticated user is required',
      );
    }
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != userId) {
      throw StateError(
        'The active Firebase user does not match the local account',
      );
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions(
    String userId, {
    String? walletId,
  }) async {
    final rows = await _queryUser(
      DatabaseTables.transactions,
      userId,
      extraWhere: walletId == null ? null : 'wallet_id = ?',
      extraArgs: walletId == null ? const [] : [walletId],
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

  /// SQLite-only write — instant. UI should await this.
  Future<void> saveTransactionLocalOnly(TransactionModel tx) async {
    _validateLocalUserRecord(tx.userId, tx.userId);
    _validateAuthenticatedUserId(tx.userId);
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseTables.transactions,
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Firestore push — fire-and-forget in the background.
  Future<void> pushTransactionRemote(TransactionModel tx) async {
    await _pushUpsert(
      table: DatabaseTables.transactions,
      userId: tx.userId,
      id: tx.id,
      sqliteRow: tx.toMap(),
      firestoreData: tx.toFirestore(),
    );
  }

  /// SQLite-only soft-delete — instant. UI should await this.
  Future<void> deleteTransactionLocalOnly(String id, String userId) async {
    _validateLocalUserId(userId);
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    await db.update(
      DatabaseTables.transactions,
      {
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
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

  /// Lightweight account-scoped wallet existence check for startup routing.
  Future<bool> hasWalletForUser(String userId) async {
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.wallets,
      columns: const ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isNotEmpty;
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
      waitForRemote: false,
    );
  }

  Future<void> updateWalletBalance(
    String walletId,
    String userId,
    double delta,
  ) async {
    _validateLocalUserId(userId);
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    final updated = await db.rawUpdate(
      'UPDATE ${DatabaseTables.wallets} SET balance = balance + ?, is_synced = 0, updated_at = ? WHERE id = ? AND user_id = ?',
      [delta, DateTime.now().toUtc().toIso8601String(), walletId, userId],
    );
    if (updated != 1) {
      throw StateError('Wallet $walletId was not found for the active account');
    }

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
      await _col(
        userId,
        DatabaseTables.wallets,
      ).doc(walletId).set(wallet.toFirestore());
      await db.update(
        DatabaseTables.wallets,
        {'is_synced': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: [walletId, userId],
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncRepository] Wallet balance push failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories(
    String userId, {
    String? walletId,
  }) async {
    _validateLocalUserId(userId);
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.categories,
      where: walletId == null
          ? "user_id = ? AND wallet_id = '' AND is_deleted = 0"
          : "user_id = ? AND (wallet_id = '' OR wallet_id = ?) AND is_deleted = 0",
      whereArgs: walletId == null ? [userId] : [userId, walletId],
      orderBy: 'name ASC',
    );
    return _uniqueBy(
      rows.map(CategoryModel.fromMap),
      (category) => category.id,
    );
  }

  Future<void> saveCategory(CategoryModel category) async {
    if (category.isBuiltIn) {
      throw ArgumentError.value(
        category.id,
        'category',
        'Built-in categories cannot be synced as user categories',
      );
    }
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

  /// SQLite-only write — instant.
  Future<void> saveCategoryLocalOnly(CategoryModel category) async {
    if (category.isBuiltIn) {
      throw ArgumentError.value(
        category.id,
        'category',
        'Built-in categories cannot be synced as user categories',
      );
    }
    _validateLocalUserRecord(category.userId, category.userId);
    _validateAuthenticatedUserId(category.userId);
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseTables.categories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Firestore push — fire-and-forget.
  Future<void> pushCategoryRemote(CategoryModel category) async {
    await _pushUpsert(
      table: DatabaseTables.categories,
      userId: category.userId,
      id: category.id,
      sqliteRow: category.toMap(),
      firestoreData: category.toFirestore(),
    );
  }

  /// SQLite-only soft-delete — instant.
  Future<void> deleteCategoryLocalOnly(String id, String userId) async {
    _validateLocalUserId(userId);
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    await db.update(
      DatabaseTables.categories,
      {
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<bool> hasRemoteCategoryReferences(
    String id,
    String userId,
    String walletId,
  ) async {
    _validateAuthenticatedUserId(userId);
    for (final table in [
      DatabaseTables.transactions,
      DatabaseTables.budgets,
    ]) {
      final snapshot = await _col(
        userId,
        table,
        walletId: walletId,
      ).where('categoryId', isEqualTo: id).limit(1).get();
      if (snapshot.docs.isNotEmpty) return true;
    }
    return false;
  }

  List<T> _uniqueBy<T>(Iterable<T> values, String Function(T value) keyOf) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (seen.add(keyOf(value))) value,
    ];
  }

  // ── Budgets ───────────────────────────────────────────────────────────────

  Future<List<BudgetModel>> getBudgets(
    String userId, {
    String? walletId,
  }) async {
    final rows = await _queryUser(
      DatabaseTables.budgets,
      userId,
      extraWhere: walletId == null ? null : 'wallet_id = ?',
      extraArgs: walletId == null ? const [] : [walletId],
    );
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

  /// SQLite-only write — instant.
  Future<void> saveBudgetLocalOnly(BudgetModel budget) async {
    _validateLocalUserRecord(budget.userId, budget.userId);
    _validateAuthenticatedUserId(budget.userId);
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseTables.budgets,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Firestore push — fire-and-forget.
  Future<void> pushBudgetRemote(BudgetModel budget) async {
    await _pushUpsert(
      table: DatabaseTables.budgets,
      userId: budget.userId,
      id: budget.id,
      sqliteRow: budget.toMap(),
      firestoreData: budget.toFirestore(),
    );
  }

  /// SQLite-only soft-delete — instant.
  Future<void> deleteBudgetLocalOnly(String id, String userId) async {
    _validateLocalUserId(userId);
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    await db.update(
      DatabaseTables.budgets,
      {
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<List<NoteModel>> getNotes(String userId, {String? walletId}) async {
    final rows = await _queryUser(
      DatabaseTables.notes,
      userId,
      extraWhere: walletId == null ? null : 'wallet_id = ?',
      extraArgs: walletId == null ? const [] : [walletId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<NoteModel?> getNote(
    String id,
    String userId, {
    String? walletId,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.notes,
      where: walletId == null
          ? 'id = ? AND user_id = ?'
          : 'id = ? AND user_id = ? AND wallet_id = ?',
      whereArgs: walletId == null ? [id, userId] : [id, userId, walletId],
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

  /// SQLite-only write — instant.
  Future<void> saveNoteLocalOnly(NoteModel note) async {
    _validateLocalUserRecord(note.userId, note.userId);
    _validateAuthenticatedUserId(note.userId);
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseTables.notes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Firestore push — fire-and-forget.
  Future<void> pushNoteRemote(NoteModel note) async {
    await _pushUpsert(
      table: DatabaseTables.notes,
      userId: note.userId,
      id: note.id,
      sqliteRow: note.toMap(),
      firestoreData: note.toFirestore(),
    );
  }

  /// SQLite-only soft-delete — instant.
  Future<void> deleteNoteLocalOnly(String id, String userId) async {
    _validateLocalUserId(userId);
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    await db.update(
      DatabaseTables.notes,
      {
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ── Generic remote push for deletes (used by optimistic providers) ────────

  /// Pushes a soft-delete to Firestore and updates the sync manifest.
  /// Fire-and-forget — never blocks the UI.
  Future<void> pushDeleteRemote({
    required String table,
    required String userId,
    required String id,
    String? walletId,
    String? updatedAt,
  }) async {
    if (!await isOnline()) return;
    final now = updatedAt ?? DateTime.now().toUtc().toIso8601String();
    try {
      if (table == DatabaseTables.wallets) {
        await _col(userId, table).doc(id).set(
          {'isDeleted': true, 'updatedAt': now},
          SetOptions(merge: true),
        ).timeout(const Duration(seconds: 15));
      } else {
        await _col(
          userId,
          table,
          walletId: walletId,
        ).doc(id).set(
          {'isDeleted': true, 'updatedAt': now},
          SetOptions(merge: true),
        ).timeout(const Duration(seconds: 15));
      }
      final db = await _dbHelper.database;
      await db.update(
        table,
        {'is_synced': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      unawaited(_updateSyncMeta(userId, table, id, 'd'));
    } catch (e) {
      debugPrint('[SyncRepository] pushDeleteRemote failed ($table/$id): $e');
    }
  }

  // ── Sync engine ───────────────────────────────────────────────────────────

  Future<void> syncPending(String userId) async {
    if (_isSyncing) {
      _syncRequested = true;
      return;
    }
    if (userId.isEmpty) return;
    _validateAuthenticatedUserId(userId);
    final db = await _dbHelper.database;
    final pendingDeletes = await db.query(
      DatabaseTables.syncQueue,
      columns: const ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final pendingRows = await db.rawQuery(
      'SELECT 1 FROM ${DatabaseTables.categories} WHERE user_id = ? AND is_synced = 0 '
      'UNION ALL SELECT 1 FROM ${DatabaseTables.wallets} WHERE user_id = ? AND is_synced = 0 '
      'UNION ALL SELECT 1 FROM ${DatabaseTables.transactions} WHERE user_id = ? AND is_synced = 0 '
      'UNION ALL SELECT 1 FROM ${DatabaseTables.budgets} WHERE user_id = ? AND is_synced = 0 '
      'UNION ALL SELECT 1 FROM ${DatabaseTables.notes} WHERE user_id = ? AND is_synced = 0 '
      'LIMIT 1',
      [userId, userId, userId, userId, userId],
    );
    if (pendingDeletes.isEmpty && pendingRows.isEmpty) return;
    if (!await isOnline()) return;

    _isSyncing = true;
    try {
      final queuedDeletes = await db.query(
        DatabaseTables.syncQueue,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      for (final row in queuedDeletes) {
        final table = row['table_name'] as String;
        final recordId = row['record_id'] as String;
        final walletId = row['wallet_id'] as String?;
        final qId = row['id'] as String;
        try {
          await _col(
            userId,
            table,
            walletId: walletId,
          ).doc(recordId).delete().timeout(const Duration(seconds: 15));
          await db.delete(
            DatabaseTables.syncQueue,
            where: 'id = ?',
            whereArgs: [qId],
          );
        } catch (e, stackTrace) {
          debugPrint('[SyncRepository] Queued delete failed: $e');
          debugPrintStack(stackTrace: stackTrace);
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
    } catch (e, stackTrace) {
      debugPrint('[SyncRepository] Sync pending failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isSyncing = false;
      if (_syncRequested) {
        _syncRequested = false;
        unawaited(syncPending(userId));
      }
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
      where: table == DatabaseTables.categories
          ? 'user_id = ? AND is_synced = 0 AND is_builtin = 0'
          : 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      final isDeleted = (row['is_deleted'] as int?) == 1;
      try {
        if (isDeleted) {
          // Push the soft-delete to Firestore.
          final walletId = row['wallet_id'] as String?;
          final now = (row['updated_at'] as String?) ??
              DateTime.now().toUtc().toIso8601String();
          await _col(
            userId,
            table,
            walletId: walletId,
          ).doc(id).set(
            {'isDeleted': true, 'updatedAt': now},
            SetOptions(merge: true),
          );
          unawaited(_updateSyncMeta(userId, table, id, 'd'));
        } else {
          await _col(
            userId,
            table,
            walletId: row['wallet_id'] as String?,
          ).doc(id).set(toFirestore(row));
          unawaited(_updateSyncMeta(userId, table, id, 'u'));
        }
        await db.update(
          table,
          {'is_synced': 1},
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );
      } catch (e, stackTrace) {
        debugPrint('[SyncRepository] Push $table/$id failed: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// Pull remote documents into SQLite using last-write-wins, without
  /// overwriting newer unsynced local edits.
  Future<bool> reconcileWithRemote(
    String userId, {
    bool preferLocal = false,
  }) async {
    if (userId.isEmpty) return false;
    _validateAuthenticatedUserId(userId);
    if (_initialReconcile != null) {
      return await _initialReconcile!;
    }
    final syncKey = '$_initialSyncPrefix$userId';
    if (await _dbHelper.getSetting(syncKey) == 'complete') {
      await syncPending(userId);
      return true;
    }
    if (!await isOnline()) return false;

    final reconcile = _performInitialReconcile(
      userId,
      preferLocal: preferLocal,
      syncKey: syncKey,
    );
    _initialReconcile = reconcile;
    try {
      return await reconcile;
    } finally {
      _initialReconcile = null;
    }
  }

  Future<bool> _performInitialReconcile(
    String userId, {
    required bool preferLocal,
    required String syncKey,
  }) async {
    try {
      final remoteWalletIds = await _mergeRemote(
        userId,
        DatabaseTables.wallets,
        (data, id) => WalletModel.fromFirestore(data, id).toMap(),
        preferLocal: preferLocal,
      );
      final walletRows = await _queryUser(DatabaseTables.wallets, userId);
      final walletIds = walletRows
          .map((row) => row['id'] as String)
          .where((id) => id.isNotEmpty)
          .toSet();
      walletIds.addAll(remoteWalletIds);
      final legacyBuiltInIds = await _legacyBuiltInCategoryIds(
        userId,
        walletIds,
      );

      for (final walletId in walletIds) {
        await _mergeRemote(
          userId,
          DatabaseTables.categories,
          (data, id) => CategoryModel.fromFirestore(data, id).toMap(),
          walletId: walletId,
          preferLocal: preferLocal,
        );
        await _mergeRemote(
          userId,
          DatabaseTables.transactions,
          (data, id) => TransactionModel.fromFirestore(
            _mapLegacyCategoryReference(data, legacyBuiltInIds),
            id,
          ).toMap(),
          walletId: walletId,
          preferLocal: preferLocal,
        );
        await _mergeRemote(
          userId,
          DatabaseTables.budgets,
          (data, id) => BudgetModel.fromFirestore(
            _mapLegacyCategoryReference(data, legacyBuiltInIds),
            id,
          ).toMap(),
          walletId: walletId,
          preferLocal: preferLocal,
        );
        await _mergeRemote(
          userId,
          DatabaseTables.notes,
          (data, id) => NoteModel.fromFirestore(data, id).toMap(),
          walletId: walletId,
          preferLocal: preferLocal,
        );
      }

      await syncPending(userId);
      await _dbHelper.setSetting(syncKey, 'complete');
      return true;
    } catch (e) {
      debugPrint('[SyncRepository] Reconcile with remote failed: $e');
      return false;
    }
  }

  Future<Map<String, String>> _legacyBuiltInCategoryIds(
    String userId,
    Set<String> walletIds,
  ) async {
    final idMap = <String, String>{};
    for (final walletId in walletIds) {
      final snapshot = await _col(
        userId,
        DatabaseTables.categories,
        walletId: walletId,
      ).get().timeout(const Duration(seconds: 20));
      for (final document in snapshot.docs) {
        final data = document.data();
        for (final category in DatabaseTables.defaultCategories) {
          if (data['name'] == category['name'] &&
              data['type'] == category['type']) {
            idMap[document.id] = CategoryModel.builtInId(
              userId,
              category['type'] as String,
              category['name'] as String,
            );
            break;
          }
        }
      }
    }
    return idMap;
  }

  Map<String, dynamic> _mapLegacyCategoryReference(
    Map<String, dynamic> data,
    Map<String, String> legacyIds,
  ) {
    final mappedData = Map<String, dynamic>.from(data);
    final categoryId = mappedData['categoryId'];
    if (categoryId is String && legacyIds.containsKey(categoryId)) {
      mappedData['categoryId'] = legacyIds[categoryId];
    }
    return mappedData;
  }

  Future<Set<String>> _mergeRemote(
    String userId,
    String table,
    Map<String, dynamic> Function(Map<String, dynamic> data, String id)
    toSqlite, {
    String? walletId,
    bool preferLocal = false,
  }) async {
    final snap = await _col(
      userId,
      table,
      walletId: walletId,
    ).get().timeout(const Duration(seconds: 20));
    final db = await _dbHelper.database;
    final remoteIds = snap.docs.map((doc) => doc.id).toSet();

    for (final doc in snap.docs) {
      if (table == DatabaseTables.categories &&
          DatabaseTables.defaultCategories.any(
            (category) =>
                category['name'] == doc.data()['name'] &&
                category['type'] == doc.data()['type'],
          )) {
        continue;
      }
      // Ownership is established by the authenticated nested path. Legacy
      // payload ownership fields, when present, are still checked.
      if (doc.data()['userId'] != null && doc.data()['userId'] != userId) {
        continue;
      }
      if (walletId != null &&
          doc.data()['walletId'] != null &&
          doc.data()['walletId'] != walletId) {
        continue;
      }
      final remoteRow = toSqlite(doc.data(), doc.id);
      remoteRow['user_id'] = userId;
      if (walletId != null) {
        remoteRow['wallet_id'] = walletId;
      }
      final existing = await db.query(
        table,
        where: walletId == null
            ? 'id = ? AND user_id = ?'
            : 'id = ? AND user_id = ? AND wallet_id = ?',
        whereArgs: walletId == null
            ? [doc.id, userId]
            : [doc.id, userId, walletId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final local = existing.first;
        final localSynced = (local['is_synced'] as int?) == 1;
        final localUpdated =
            DateTime.tryParse((local['updated_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final remoteUpdated =
            DateTime.tryParse((remoteRow['updated_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        if (preferLocal && !localSynced) {
          continue;
        }
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

    // A successful full collection read is authoritative for already-synced
    // rows. Keep unsynced local edits so an offline delete/update can still
    // be uploaded on the next sync.
    final localRows = await db.query(
      table,
      columns: ['id'],
      where: table == DatabaseTables.categories
          ? walletId == null
                ? 'user_id = ? AND is_synced = 1 AND is_builtin = 0'
                : 'user_id = ? AND wallet_id = ? AND is_synced = 1 AND is_builtin = 0'
          : walletId == null
          ? 'user_id = ? AND is_synced = 1'
          : 'user_id = ? AND wallet_id = ? AND is_synced = 1',
      whereArgs: walletId == null ? [userId] : [userId, walletId],
    );
    for (final localRow in localRows) {
      final localId = localRow['id'] as String;
      if (!remoteIds.contains(localId)) {
        await db.delete(
          table,
          where: table == DatabaseTables.categories
              ? walletId == null
                    ? 'id = ? AND user_id = ? AND is_synced = 1 AND is_builtin = 0'
                    : 'id = ? AND user_id = ? AND wallet_id = ? AND is_synced = 1 AND is_builtin = 0'
              : walletId == null
              ? 'id = ? AND user_id = ? AND is_synced = 1'
              : 'id = ? AND user_id = ? AND wallet_id = ? AND is_synced = 1',
          whereArgs: walletId == null
              ? [localId, userId]
              : [localId, userId, walletId],
        );
      }
    }
    return remoteIds;
  }

  // ── Sync Manifest (Ultra-low-cost multi-device sync) ──────────────────────

  /// The single Firestore document that tracks what changed across all devices.
  /// Location: users/{userId}/meta/sync
  DocumentReference<Map<String, dynamic>> _syncMetaRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('meta')
        .doc('sync');
  }

  /// Appends a change entry to the manifest after a successful Firestore write.
  /// Uses server-side FieldValue so this costs 1 write and 0 reads.
  /// Format: "table:recordId:operation" (e.g. "transactions:abc123:u")
  Future<void> _updateSyncMeta(
    String userId,
    String table,
    String recordId,
    String operation, // 'c' create, 'u' update, 'd' delete
  ) async {
    try {
      await _syncMetaRef(userId).set(
        {
          'v': FieldValue.increment(1),
          'changes': FieldValue.arrayUnion(['$table:$recordId:$operation']),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // Non-critical: the manifest failing does not break local writes.
      // The fallback is the existing reconcileWithRemote() path.
      debugPrint('[SyncRepository] _updateSyncMeta failed: $e');
    }
  }

  /// Ultra-low-cost sync triggered on every app open / foreground resume.
  ///
  /// Fast path  (nothing changed) → 1 Firestore read total.
  /// Slow path  (N records changed) → 1 + N reads.
  /// Delete entries → 0 reads (just removes from local SQLite).
  /// Checks for remote changes and pulls them into SQLite when found.
  ///
  /// Returns `true` when new data was actually merged into the local database
  /// (callers should refresh their UI). Returns `false` on the fast path
  /// (version unchanged) or when offline — meaning no UI refresh is needed.
  Future<bool> syncOnAppOpen(String userId) async {
    if (userId.isEmpty || !await isOnline()) return false;
    _validateAuthenticatedUserId(userId);

    // Always push any locally pending changes first.
    await syncPending(userId);

    try {
      // ── STEP 1: Read the single manifest document (1 read) ──────────────
      final metaDoc = await _syncMetaRef(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!metaDoc.exists) return false; // No remote data yet.

      final remoteVersion = (metaDoc.data()?['v'] as num?)?.toInt() ?? 0;
      final localVersionStr =
          await _dbHelper.getSetting('$_syncVersionPrefix$userId');
      final localVersion = int.tryParse(localVersionStr ?? '0') ?? 0;

      // ── FAST PATH: version unchanged → done in 1 read, no UI refresh ────
      if (remoteVersion <= localVersion) return false;

      final changes = (metaDoc.data()?['changes'] as List?)
              ?.cast<String>() ??
          <String>[];

      if (changes.isEmpty) {
        // Version bumped but no entries — fall back to incremental reconcile.
        debugPrint(
          '[SyncRepository] Manifest empty, falling back to reconcile.',
        );
        await reconcileWithRemote(userId);
      } else {
        // ── SLOW PATH: fetch only the specific changed records ────────────
        await _processChangeEntries(userId, changes);
      }

      // Persist the new version locally.
      await _dbHelper.setSetting(
        '$_syncVersionPrefix$userId',
        remoteVersion.toString(),
      );

      // Clear processed entries from the manifest (1 write).
      // Safe for personal use (1-2 devices). For shared wallets with many
      // concurrent writers, persist per-device read cursors instead.
      await _syncMetaRef(userId).update({'changes': <String>[]});

      // New data was merged — caller should refresh the UI.
      return true;
    } catch (e) {
      debugPrint('[SyncRepository] syncOnAppOpen failed: $e');
      return false;
    }
  }

  /// Fetches only the specific records listed in [changes] and merges them
  /// into local SQLite. Deletes cost 0 Firestore reads.
  Future<void> _processChangeEntries(
    String userId,
    List<String> changes,
  ) async {
    final db = await _dbHelper.database;

    // Deduplicate: if the same record appears multiple times keep the last
    // entry (latest operation wins). Iterate reversed, add to seen set.
    final seen = <String>{};
    final unique = changes.reversed
        .where((e) {
          final key = e.substring(0, e.lastIndexOf(':'));
          return seen.add(key);
        })
        .toList()
        .reversed
        .toList();

    for (final entry in unique) {
      final parts = entry.split(':');
      if (parts.length != 3) continue;

      final table = parts[0];
      final recordId = parts[1];
      final operation = parts[2];

      if (operation == 'd') {
        // DELETE — remove from local SQLite. Zero Firestore reads.
        await db.delete(
          table,
          where: 'id = ? AND user_id = ?',
          whereArgs: [recordId, userId],
        );
        continue;
      }

      // CREATE or UPDATE — fetch the specific document by ID (1 read).
      try {
        // Determine walletId from local row (cheapest path) or fall back
        // to querying all wallets.
        final walletId = await _resolveWalletIdForRecord(
          db,
          table,
          recordId,
          userId,
        );
        if (walletId == null) continue;

        final doc = await _col(userId, table, walletId: walletId)
            .doc(recordId)
            .get()
            .timeout(const Duration(seconds: 10));

        if (!doc.exists) continue;
        final data = doc.data()!;

        // Soft-deleted remotely → remove locally.
        if (data['isDeleted'] == true) {
          await db.delete(
            table,
            where: 'id = ? AND user_id = ?',
            whereArgs: [recordId, userId],
          );
          continue;
        }

        // Conflict resolution: last-write-wins on updatedAt.
        final existing = await db.query(
          table,
          where: 'id = ? AND user_id = ?',
          whereArgs: [recordId, userId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final local = existing.first;
          final localSynced = (local['is_synced'] as int?) == 1;
          if (!localSynced) {
            final localUpdated = DateTime.tryParse(
                  (local['updated_at'] as String?) ?? '',
                ) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final remoteUpdated = DateTime.tryParse(
                  (data['updatedAt'] as String?) ?? '',
                ) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            if (!remoteUpdated.isAfter(localUpdated)) {
              continue; // Local is newer — keep it.
            }
          }
        }

        // Apply remote change into SQLite.
        final sqliteRow = _firestoreToSqlite(table, data, recordId);
        sqliteRow['user_id'] = userId;
        sqliteRow['wallet_id'] = walletId;
        sqliteRow['is_synced'] = 1;
        sqliteRow['is_deleted'] = 0;

        await db.insert(
          table,
          sqliteRow,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint(
          '[SyncRepository] Failed to process change entry "$entry": $e',
        );
      }
    }
  }

  /// Resolves the wallet ID for a given record.
  /// Checks the local SQLite row first (free), then falls back to
  /// reading the wallets list (cheap, cached).
  Future<String?> _resolveWalletIdForRecord(
    Database db,
    String table,
    String recordId,
    String userId,
  ) async {
    // Wallets have no wallet sub-path — they live at the user level.
    if (table == DatabaseTables.wallets) return null;

    // Try to read wallet_id from the existing local row.
    final rows = await db.query(
      table,
      columns: ['wallet_id'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [recordId, userId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final wid = rows.first['wallet_id'] as String?;
      if (wid != null && wid.isNotEmpty) return wid;
    }

    // Record is new on this device — use the first available wallet.
    final wallets = await db.query(
      DatabaseTables.wallets,
      columns: ['id'],
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (wallets.isNotEmpty) return wallets.first['id'] as String?;
    return null;
  }

  /// Converts a Firestore document payload to a SQLite row map
  /// using the existing fromFirestore factory constructors.
  Map<String, dynamic> _firestoreToSqlite(
    String table,
    Map<String, dynamic> data,
    String docId,
  ) {
    switch (table) {
      case DatabaseTables.transactions:
        return TransactionModel.fromFirestore(data, docId).toMap();
      case DatabaseTables.categories:
        return CategoryModel.fromFirestore(data, docId).toMap();
      case DatabaseTables.budgets:
        return BudgetModel.fromFirestore(data, docId).toMap();
      case DatabaseTables.notes:
        return NoteModel.fromFirestore(data, docId).toMap();
      case DatabaseTables.wallets:
        return WalletModel.fromFirestore(data, docId).toMap();
      default:
        throw ArgumentError('Unknown table: $table');
    }
  }
}
