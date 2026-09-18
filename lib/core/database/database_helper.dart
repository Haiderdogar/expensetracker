import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../security/secure_storage_service.dart';
import '../utils/error_handler.dart';
import 'database_tables.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'expense_tracker.db';
  static const _installationIdKey = 'installation_id';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Permanently removes all locally stored account data.
  Future<void> resetDatabase() async {
    try {
      final activeDatabase = _database;
      _database = null;
      if (activeDatabase != null) await activeDatabase.close();

      final dbPath = await getDatabasesPath();
      await deleteDatabase(join(dbPath, _dbName));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> initializeInstallationIdentity(
    SecureStorageService storage,
  ) async {
    await database;
    final databaseId = await getSetting(_installationIdKey);
    if (databaseId == null || databaseId.isEmpty) {
      // A missing marker is an incomplete or new database. Do not let old
      // Keychain/Keystore credentials unlock it.
      await storage.clearAuthentication();
      final installationId = const Uuid().v4();
      await setSetting(_installationIdKey, installationId);
      await storage.saveInstallationId(installationId);
      return;
    }

    final secureId = await storage.readInstallationId();
    if (secureId == null || secureId.isEmpty) {
      // Existing installations gain the secure marker without losing their
      // already-configured lock credentials.
      await storage.saveInstallationId(databaseId);
      return;
    }

    if (secureId != databaseId) {
      // Keychain/Keystore data can survive an uninstall while SQLite data
      // does not. Its credentials must not unlock the new installation.
      await storage.clearAuthentication();
      await storage.saveInstallationId(databaseId);
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      return await openDatabase(
        path,
        version: DatabaseTables.dbVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute(DatabaseTables.createCategories);
      await db.execute(DatabaseTables.createWallets);
      await db.execute(DatabaseTables.createTransactions);
      await db.execute(DatabaseTables.createBudgets);
      await db.execute(DatabaseTables.createSettings);
      await db.execute(DatabaseTables.createNotes);
      await db.execute(DatabaseTables.createSyncQueue);
      await db.insert(DatabaseTables.settings, {
        'key': 'account_created_at',
        'value': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert(DatabaseTables.settings, {
        'key': _installationIdKey,
        'value': const Uuid().v4(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(DatabaseTables.createNotes);
    }
    if (oldVersion < 3) {
      await db.execute(DatabaseTables.createSubcategories);
      await db.execute(
        'ALTER TABLE ${DatabaseTables.transactions} ADD COLUMN subcategory TEXT NOT NULL DEFAULT \'\'',
      );
      await db.execute(
        'UPDATE ${DatabaseTables.transactions} SET subcategory = title WHERE subcategory = \'\'',
      );
    }
    if (oldVersion < 5) {
      await db.insert(DatabaseTables.settings, {
        'key': _installationIdKey,
        'value': const Uuid().v4(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (oldVersion < 6) {
      await _seedMissingDefaultCategories(db, 'default_user');
    }
    if (oldVersion < 7) {
      // Add sync queue table
      await db.execute(DatabaseTables.createSyncQueue);

      // Add user_id, is_synced, and updated_at columns
      await _safeAddColumn(
        db,
        DatabaseTables.categories,
        'user_id',
        'TEXT NOT NULL DEFAULT \'default_user\'',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.categories,
        'is_synced',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.categories,
        'updated_at',
        'TEXT NOT NULL DEFAULT \'\'',
      );

      await _safeAddColumn(
        db,
        DatabaseTables.wallets,
        'user_id',
        'TEXT NOT NULL DEFAULT \'default_user\'',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.wallets,
        'is_synced',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.wallets,
        'updated_at',
        'TEXT NOT NULL DEFAULT \'\'',
      );

      await _safeAddColumn(
        db,
        DatabaseTables.transactions,
        'user_id',
        'TEXT NOT NULL DEFAULT \'default_user\'',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.transactions,
        'is_synced',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.transactions,
        'updated_at',
        'TEXT NOT NULL DEFAULT \'\'',
      );

      await _safeAddColumn(
        db,
        DatabaseTables.subcategories,
        'user_id',
        'TEXT NOT NULL DEFAULT \'default_user\'',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.subcategories,
        'is_synced',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.subcategories,
        'updated_at',
        'TEXT NOT NULL DEFAULT \'\'',
      );

      await _safeAddColumn(
        db,
        DatabaseTables.budgets,
        'user_id',
        'TEXT NOT NULL DEFAULT \'default_user\'',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.budgets,
        'is_synced',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.budgets,
        'updated_at',
        'TEXT NOT NULL DEFAULT \'\'',
      );

      await _safeAddColumn(
        db,
        DatabaseTables.notes,
        'user_id',
        'TEXT NOT NULL DEFAULT \'default_user\'',
      );
      await _safeAddColumn(
        db,
        DatabaseTables.notes,
        'is_synced',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 8) {
      for (final table in [
        DatabaseTables.categories,
        DatabaseTables.transactions,
        DatabaseTables.budgets,
        DatabaseTables.notes,
      ]) {
        await _safeAddColumn(
          db,
          table,
          'wallet_id',
          "TEXT NOT NULL DEFAULT ''",
        );
      }
      await _assignRecordsToFirstWallet(db);
      await _safeAddColumn(
        db,
        DatabaseTables.syncQueue,
        'wallet_id',
        "TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 9) {
      await db.execute(
        'UPDATE ${DatabaseTables.transactions} SET title = subcategory WHERE subcategory IS NOT NULL AND TRIM(subcategory) <> \'\'',
      );
      await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.subcategories}');
    }
  }

  Future<void> _assignRecordsToFirstWallet(Database db) async {
    for (final table in [
      DatabaseTables.categories,
      DatabaseTables.transactions,
      DatabaseTables.budgets,
      DatabaseTables.notes,
    ]) {
      await db.execute('''
        UPDATE $table
        SET wallet_id = (
          SELECT id FROM ${DatabaseTables.wallets} w
          WHERE w.user_id = $table.user_id
          ORDER BY w.id ASC LIMIT 1
        )
        WHERE wallet_id = ''
      ''');
    }
  }

  Future<void> _safeAddColumn(
    Database db,
    String table,
    String col,
    String def,
  ) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $col $def');
    } catch (_) {
      // Column might already exist.
    }
  }

  Future<void> ensureUserInitialized(String userId) async {
    final db = await database;
    final existingCategories = await db.query(
      DatabaseTables.categories,
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (existingCategories.isEmpty) {
      await _seedDefaultCategories(db, userId);
    } else {
      await _seedMissingDefaultCategories(db, userId);
    }

    final existingWallets = await db.query(
      DatabaseTables.wallets,
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (existingWallets.isEmpty) {
      const uuid = Uuid();
      final now = DateTime.now().toUtc().toIso8601String();
      await db.insert(DatabaseTables.wallets, {
        'id': uuid.v4(),
        'user_id': userId,
        'name': 'Main Wallet',
        'balance': 0.0,
        'is_synced': 0,
        'updated_at': now,
      });
    }

    final wallet = await db.query(
      DatabaseTables.wallets,
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (wallet.isNotEmpty) {
      await _assignUserRecordsToWallet(
        db,
        userId,
        wallet.first['id'] as String,
      );
    }
  }

  Future<void> _assignUserRecordsToWallet(
    Database db,
    String userId,
    String walletId,
  ) async {
    for (final table in [
      DatabaseTables.categories,
      DatabaseTables.transactions,
      DatabaseTables.budgets,
      DatabaseTables.notes,
    ]) {
      await db.update(
        table,
        {'wallet_id': walletId},
        where: 'user_id = ? AND wallet_id = ?',
        whereArgs: [userId, ''],
      );
    }
  }

  Future<void> ensureWalletDefaults(String userId, String walletId) async {
    final db = await database;
    final existing = await db.query(
      DatabaseTables.categories,
      columns: ['id'],
      where: 'user_id = ? AND wallet_id = ?',
      whereArgs: [userId, walletId],
      limit: 1,
    );
    if (existing.isEmpty) {
      await _seedDefaultCategories(db, userId, walletId: walletId);
    }
  }

  /// Moves all records from the local guest partition to an authenticated
  /// account while preserving every record ID and account-scoped setting.
  Future<void> migrateGuestData(String userId) async {
    if (userId.isEmpty || userId == 'default_user') {
      throw ArgumentError.value(
        userId,
        'userId',
        'An authenticated user is required',
      );
    }

    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        DatabaseTables.transactions,
        DatabaseTables.budgets,
        DatabaseTables.notes,
        DatabaseTables.categories,
        DatabaseTables.wallets,
      ]) {
        await txn.update(
          table,
          {'user_id': userId, 'is_synced': 0},
          where: 'user_id = ?',
          whereArgs: ['default_user'],
        );
      }

      final guestSettings = await txn.query(
        DatabaseTables.settings,
        where: 'key LIKE ?',
        whereArgs: ['%_default_user'],
      );
      for (final setting in guestSettings) {
        final key = setting['key'] as String;
        await txn.insert(DatabaseTables.settings, {
          'key': key.replaceFirst('_default_user', '_$userId'),
          'value': setting['value'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Removes only guest account data. Installation identity and global
  /// preferences intentionally remain intact.
  Future<void> clearGuestData() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        DatabaseTables.transactions,
        DatabaseTables.budgets,
        DatabaseTables.notes,
        DatabaseTables.categories,
        DatabaseTables.wallets,
      ]) {
        await txn.delete(
          table,
          where: 'user_id = ?',
          whereArgs: ['default_user'],
        );
      }

      await txn.delete(
        DatabaseTables.syncQueue,
        where: 'user_id = ?',
        whereArgs: ['default_user'],
      );
      await txn.delete(
        DatabaseTables.settings,
        where: 'key LIKE ?',
        whereArgs: ['%_default_user'],
      );
    });
  }

  Future<void> _seedDefaultCategories(
    Database db,
    String userId, {
    String? walletId,
  }) async {
    const uuid = Uuid();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final category in DatabaseTables.defaultCategories) {
      final categoryId = uuid.v4();
      await db.insert(DatabaseTables.categories, {
        'id': categoryId,
        'user_id': userId,
        'wallet_id': walletId ?? '',
        'name': category['name'],
        'type': category['type'],
        'icon': category['icon'],
        'color': category['color'],
        'is_synced': 0,
        'updated_at': now,
      });
    }
  }

  Future<void> _seedMissingDefaultCategories(Database db, String userId) async {
    const uuid = Uuid();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final category in DatabaseTables.defaultCategories) {
      final existing = await db.query(
        DatabaseTables.categories,
        columns: ['id'],
        where: 'user_id = ? AND name = ? AND type = ?',
        whereArgs: [userId, category['name'], category['type']],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;
      await db.insert(DatabaseTables.categories, {
        'id': uuid.v4(),
        'user_id': userId,
        'name': category['name'],
        'type': category['type'],
        'icon': category['icon'],
        'color': category['color'],
        'is_synced': 0,
        'updated_at': now,
      });
    }
  }

  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final rows = await db.query(
        DatabaseTables.settings,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['value'] as String?;
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(DatabaseTables.settings, {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> saveGoogleProfile({
    required String userId,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) async {
    if (userId.isEmpty || userId == 'default_user') {
      throw ArgumentError.value(
        userId,
        'userId',
        'An authenticated user is required',
      );
    }
    await Future.wait([
      setSetting('profile_name_$userId', displayName?.trim() ?? ''),
      setSetting('profile_email_$userId', email?.trim() ?? ''),
      setSetting('profile_photo_url_$userId', photoUrl?.trim() ?? ''),
      setSetting('auth_provider_$userId', 'google'),
    ]);
  }

  Future<bool> isOnboardingComplete([String? userId]) async {
    final key = userId != null
        ? 'onboarding_complete_$userId'
        : 'onboarding_complete';
    final value = await getSetting(key);
    return value == 'true';
  }

  Future<void> setOnboardingComplete(bool complete, [String? userId]) async {
    final key = userId != null
        ? 'onboarding_complete_$userId'
        : 'onboarding_complete';
    await setSetting(key, complete ? 'true' : 'false');
  }

  Future<String> getCurrencySymbol([String? userId]) async {
    final key = userId != null ? 'currency_symbol_$userId' : 'currency_symbol';
    final sym = await getSetting(key);
    if (sym != null && sym.isNotEmpty) return sym;
    return await getSetting('currency_symbol') ?? '\$';
  }

  Future<void> setCurrencySymbol(String symbol, [String? userId]) async {
    if (userId != null) {
      await setSetting('currency_symbol_$userId', symbol);
    }
    await setSetting('currency_symbol', symbol);
  }

  Future<String?> getThemeMode() async {
    return await getSetting('theme_mode');
  }

  Future<void> setThemeMode(String mode) async {
    await setSetting('theme_mode', mode);
  }

  Future<String?> getSelectedWalletId([String? userId]) async {
    final key = userId != null
        ? 'selected_wallet_id_$userId'
        : 'selected_wallet_id';
    final id = await getSetting(key);
    if (id != null && id.isNotEmpty) return id;
    return await getSetting('selected_wallet_id');
  }

  Future<void> setSelectedWalletId(String? walletId, [String? userId]) async {
    final key = userId != null
        ? 'selected_wallet_id_$userId'
        : 'selected_wallet_id';
    if (walletId == null || walletId.isEmpty) {
      await setSetting(key, '');
      await setSetting('selected_wallet_id', '');
      return;
    }
    await setSetting(key, walletId);
    await setSetting('selected_wallet_id', walletId);
  }

  Future<DateTime> getAccountCreatedAt() async {
    final raw = await getSetting('account_created_at');
    final parsed = raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);
    final createdAt = parsed ?? DateTime.now();
    if (raw == null || raw.isEmpty) {
      await setSetting(
        'account_created_at',
        createdAt.toUtc().toIso8601String(),
      );
    }
    return createdAt;
  }

  Future<void> setAccountCreatedAt(DateTime date) async {
    await setSetting('account_created_at', date.toUtc().toIso8601String());
  }
}
