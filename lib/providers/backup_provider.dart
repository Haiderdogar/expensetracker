import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import 'database_provider.dart';

part 'backup_provider.g.dart';

@Riverpod(keepAlive: true)
class BackupService extends _$BackupService {
  @override
  void build() {}

  Future<Map<String, dynamic>> exportAll() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final data = <String, dynamic>{};

      for (final table in [
        DatabaseTables.categories,
        DatabaseTables.wallets,
        DatabaseTables.transactions,
        DatabaseTables.budgets,
        DatabaseTables.settings,
      ]) {
        data[table] = await db.query(table);
      }

      return data;
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> shareExport() async {
    final data = await exportAll();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expense_tracker_backup.json');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)], text: 'Expense Tracker Backup');
  }

  Future<void> importFromJson(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final db = await ref.read(databaseProvider.future);

      await db.transaction((txn) async {
        for (final table in [
          DatabaseTables.transactions,
          DatabaseTables.budgets,
          DatabaseTables.wallets,
          DatabaseTables.categories,
          DatabaseTables.settings,
        ]) {
          await txn.delete(table);
        }

        for (final table in [
          DatabaseTables.categories,
          DatabaseTables.wallets,
          DatabaseTables.transactions,
          DatabaseTables.budgets,
          DatabaseTables.settings,
        ]) {
          final rows = (data[table] as List?) ?? [];
          for (final row in rows) {
            await txn.insert(table, Map<String, dynamic>.from(row as Map));
          }
        }
      });
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}

@riverpod
Future<Map<String, double>> expenseByCategory(Ref ref) async {
  // Depend on transactions and categories so this provider auto-refreshes when they change
  await ref.watch(transactionsProvider.future);
  await ref.watch(categoriesProvider.future);

  final db = await ref.watch(databaseProvider.future);
  final rows = await db.rawQuery('''
    SELECT c.name, c.color, SUM(t.amount) as total
    FROM ${DatabaseTables.transactions} t
    JOIN ${DatabaseTables.categories} c ON t.category_id = c.id
    WHERE t.type = 'expense'
    GROUP BY c.id
    ORDER BY total DESC
  ''');

  return {
    for (final row in rows)
      row['name'] as String: (row['total'] as num).toDouble(),
  };
}

@riverpod
Future<List<MapEntry<String, double>>> monthlySpendingTrend(
  Ref ref,
) async {
  // Depend on transactions so chart refreshes automatically on changes
  await ref.watch(transactionsProvider.future);

  final db = await ref.watch(databaseProvider.future);
  final rows = await db.rawQuery('''
    SELECT substr(date, 1, 7) as month, SUM(amount) as total
    FROM ${DatabaseTables.transactions}
    WHERE type = 'expense'
    GROUP BY month
    ORDER BY month ASC
    LIMIT 6
  ''');

  return rows
      .map((r) => MapEntry(r['month'] as String, (r['total'] as num).toDouble()))
      .toList();
}
