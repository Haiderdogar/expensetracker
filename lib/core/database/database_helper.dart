import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../utils/error_handler.dart';
import 'database_tables.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'expense_tracker.db';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
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
      await db.insert(DatabaseTables.settings, {
        'key': 'account_created_at',
        'value': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _seedDefaultCategories(db);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    const uuid = Uuid();
    for (final category in DatabaseTables.defaultCategories) {
      await db.insert(DatabaseTables.categories, {
        'id': uuid.v4(),
        'name': category['name'],
        'type': category['type'],
        'icon': category['icon'],
        'color': category['color'],
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
