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
      await db.execute(DatabaseTables.createSubcategories);
      await db.execute(DatabaseTables.createBudgets);
      await db.execute(DatabaseTables.createSettings);
      await db.execute(DatabaseTables.createNotes);
      await db.insert(DatabaseTables.settings, {
        'key': 'account_created_at',
        'value': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert(DatabaseTables.settings, {
        'key': _installationIdKey,
        'value': const Uuid().v4(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _seedDefaultCategories(db);
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
    if (oldVersion < 4) {
      await _seedSubcategoriesForExistingCategories(db);
    }
    if (oldVersion < 5) {
      await db.insert(DatabaseTables.settings, {
        'key': _installationIdKey,
        'value': const Uuid().v4(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    const uuid = Uuid();
    for (final category in DatabaseTables.defaultCategories) {
      final categoryId = uuid.v4();
      await db.insert(DatabaseTables.categories, {
        'id': categoryId,
        'name': category['name'],
        'type': category['type'],
        'icon': category['icon'],
        'color': category['color'],
      });
    }
    await _seedSubcategoriesForExistingCategories(db);
  }

  Future<void> _seedSubcategoriesForExistingCategories(Database db) async {
    const uuid = Uuid();
    final categories = await db.query(DatabaseTables.categories);
    for (final category in categories) {
      final names = DatabaseTables.defaultSubcategories[category['name']];
      if (names == null) continue;
      for (final name in names) {
        await db.insert(
          DatabaseTables.subcategories,
          {'id': uuid.v4(), 'category_id': category['id'], 'name': name},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
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

  Future<bool> isOnboardingComplete() async {
    final value = await getSetting('onboarding_complete');
    return value == 'true';
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await setSetting('onboarding_complete', complete ? 'true' : 'false');
  }

  Future<String> getCurrencySymbol() async {
    return await getSetting('currency_symbol') ?? '\$';
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await setSetting('currency_symbol', symbol);
  }

  Future<String?> getThemeMode() async {
    return await getSetting('theme_mode');
  }

  Future<void> setThemeMode(String mode) async {
    await setSetting('theme_mode', mode);
  }

  Future<String?> getSelectedWalletId() async {
    return await getSetting('selected_wallet_id');
  }

  Future<void> setSelectedWalletId(String? walletId) async {
    if (walletId == null || walletId.isEmpty) {
      await setSetting('selected_wallet_id', '');
      return;
    }
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
