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
  }) async {
    _validateLocalUserRecord(userId, sqliteRow['user_id']);
    if (userId != 'default_user') {
      _validateAuthenticatedUserId(userId);
    }
    final db = await _dbHelper.database;
    await db.insert(
      table,
      sqliteRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Guest data is intentionally local-only.
    if (userId == 'default_user') return;
    if (table != DatabaseTables.categories &&
        table != DatabaseTables.transactions) {
      _validateRemoteUserRecord(userId, firestoreData['userId']);
    }

    if (!await isOnline()) return;
    try {
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
    if (userId != 'default_user') {
      _validateAuthenticatedUserId(userId);
    }
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

    await db.delete(
      table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (userId == 'default_user') return;

    await db.insert(DatabaseTables.syncQueue, {
      'id': const Uuid().v4(),
      'table_name': table,
      'record_id': id,
      'wallet_id': walletId ?? '',
      'operation': 'delete',
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (!await isOnline()) return;
    try {
      await _col(
        userId,
        table,
        walletId: walletId,
      ).doc(id).delete().timeout(const Duration(seconds: 15));
      await db.delete(
        DatabaseTables.syncQueue,
        where: 'table_name = ? AND record_id = ? AND user_id = ?',
        whereArgs: [table, id, userId],
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncRepository] Immediate delete failed ($table/$id): $e');
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
    final where = extraWhere == null
        ? 'user_id = ?'
        : 'user_id = ? AND $extraWhere';
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

  /// Firestore rules provide the server-side enforcement; this is a redundant
  /// client-side guard before uploading a record.
  void _validateRemoteUserRecord(String userId, Object? remoteUserId) {
    _validateAuthenticatedUserId(userId);
    if (remoteUserId != userId) {
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
    if (userId.isEmpty || userId == 'default_user') {
      throw ArgumentError.value(
        userId,
        'userId',
        'An authenticated user is required',
      );
    }
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != userId) {
      throw StateError('The active Firebase user does not match the local account');
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
    );
  }

  Future<void> updateWalletBalance(
    String walletId,
    String userId,
    double delta,
  ) async {
    _validateLocalUserId(userId);
    if (userId != 'default_user') {
      _validateAuthenticatedUserId(userId);
    }
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
    final rows = await _queryUser(
      DatabaseTables.categories,
      userId,
      extraWhere: walletId == null ? null : 'wallet_id = ?',
      extraArgs: walletId == null ? const [] : [walletId],
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

  List<T> _uniqueBy<T>(Iterable<T> values, String Function(T value) keyOf) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (seen.add(keyOf(value))) value,
    ];
  }

  String _normalizedName(String value) => value.trim().toLowerCase();

  /// Uploads the guest partition under an authenticated UID before changing
  /// local ownership. Existing documents with the same IDs are intentionally
  /// overwritten by the guest's local state.
  Future<void> migrateGuestData(String userId) async {
    _validateAuthenticatedUserId(userId);
    if (!await isOnline()) {
      throw StateError(
        'An internet connection is required to upgrade a guest account.',
      );
    }

    final db = await _dbHelper.database;
    await _migrateTable(
      db,
      userId,
      DatabaseTables.categories,
      (row) => CategoryModel.fromMap({...row, 'user_id': userId}).toFirestore(),
    );
    await _migrateTable(
      db,
      userId,
      DatabaseTables.wallets,
      (row) => WalletModel.fromMap({...row, 'user_id': userId}).toFirestore(),
    );
    await _migrateTable(
      db,
      userId,
      DatabaseTables.transactions,
      (row) =>
          TransactionModel.fromMap({...row, 'user_id': userId}).toFirestore(),
    );
    await _migrateTable(
      db,
      userId,
      DatabaseTables.budgets,
      (row) => BudgetModel.fromMap({...row, 'user_id': userId}).toFirestore(),
    );
    await _migrateTable(
      db,
      userId,
      DatabaseTables.notes,
      (row) => NoteModel.fromMap({...row, 'user_id': userId}).toFirestore(),
    );

    await _dbHelper.migrateGuestData(userId);
  }

  Future<void> _migrateTable(
    Database db,
    String userId,
    String table,
    Map<String, dynamic> Function(Map<String, dynamic> row) toFirestore,
  ) async {
    final rows = await db.query(
      table,
      where: 'user_id = ?',
      whereArgs: ['default_user'],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      await _col(
        userId,
        table,
        walletId: row['wallet_id'] as String?,
      ).doc(id).set(toFirestore(row)).timeout(const Duration(seconds: 15));
    }
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

  // ── Sync engine ───────────────────────────────────────────────────────────

  Future<void> syncPending(String userId) async {
    if (_isSyncing) {
      _syncRequested = true;
      return;
    }
    if (userId.isEmpty || userId == 'default_user') return;
    _validateAuthenticatedUserId(userId);
    if (!await isOnline()) return;

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
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      try {
        await _col(
          userId,
          table,
          walletId: row['wallet_id'] as String?,
        ).doc(id).set(toFirestore(row));
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
  Future<void> reconcileWithRemote(
    String userId, {
    bool preferLocal = false,
  }) async {
    if (userId.isEmpty || userId == 'default_user') return;
    _validateAuthenticatedUserId(userId);
    if (!await isOnline()) return;

    try {
      await _mergeRemote(
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
      final remoteWallets = await _col(userId, DatabaseTables.wallets).get();
      walletIds.addAll(remoteWallets.docs.map((doc) => doc.id));

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
          (data, id) => TransactionModel.fromFirestore(data, id).toMap(),
          walletId: walletId,
          preferLocal: preferLocal,
        );
        await _mergeRemote(
          userId,
          DatabaseTables.budgets,
          (data, id) => BudgetModel.fromFirestore(data, id).toMap(),
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
    } catch (e) {
      debugPrint('[SyncRepository] Reconcile with remote failed: $e');
    }
  }

  Future<void> _mergeRemote(
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
      where: walletId == null
          ? 'user_id = ? AND is_synced = 1'
          : 'user_id = ? AND wallet_id = ? AND is_synced = 1',
      whereArgs: walletId == null ? [userId] : [userId, walletId],
    );
    for (final localRow in localRows) {
      final localId = localRow['id'] as String;
      if (!remoteIds.contains(localId)) {
        await db.delete(
          table,
          where: walletId == null
              ? 'id = ? AND user_id = ? AND is_synced = 1'
              : 'id = ? AND user_id = ? AND wallet_id = ? AND is_synced = 1',
          whereArgs: walletId == null
              ? [localId, userId]
              : [localId, userId, walletId],
        );
      }
    }
  }
}
