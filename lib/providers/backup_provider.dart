import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import 'auth_provider.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

part 'backup_provider.g.dart';

@Riverpod(keepAlive: true)
class BackupService extends _$BackupService {
  @override
  void build() {}

  Future<Map<String, dynamic>> exportAll() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final userId = ref.read(currentUserIdProvider);
      final data = <String, dynamic>{};

      for (final table in [
        DatabaseTables.categories,
        DatabaseTables.wallets,
        DatabaseTables.transactions,
        DatabaseTables.budgets,
        DatabaseTables.notes,
      ]) {
        data[table] = await db.query(
          table,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      data[DatabaseTables.settings] = await db.query(DatabaseTables.settings);
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
      final userId = ref.read(currentUserIdProvider);

      await db.transaction((txn) async {
        for (final table in [
          DatabaseTables.transactions,
          DatabaseTables.budgets,
          DatabaseTables.notes,
          DatabaseTables.wallets,
          DatabaseTables.categories,
        ]) {
          await txn.delete(
            table,
            where: 'user_id = ?',
            whereArgs: [userId],
          );
        }

        for (final table in [
          DatabaseTables.categories,
          DatabaseTables.wallets,
          DatabaseTables.transactions,
          DatabaseTables.budgets,
          DatabaseTables.notes,
        ]) {
          final rows = (data[table] as List?) ?? [];
          for (final row in rows) {
            final mapped = Map<String, dynamic>.from(row as Map);
            mapped['user_id'] = userId;
            mapped['is_synced'] = 0;
            if (table == DatabaseTables.transactions) {
              mapped['title'] ??= mapped['subcategory'] ?? '';
              mapped.remove('subcategory');
            }
            await txn.insert(table, mapped);
          }
        }
      });

      await ref.read(syncRepositoryProvider).syncPending(userId);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}

@riverpod
Future<Map<String, double>> expenseByCategory(Ref ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  final names = {for (final c in categories) c.id: c.name};
  final totals = <String, double>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    final name = names[t.categoryId] ?? 'Other';
    totals[name] = (totals[name] ?? 0) + t.amount;
  }
  return totals;
}

@riverpod
Future<List<MapEntry<String, double>>> monthlySpendingTrend(Ref ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final totals = <String, double>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    final month = t.date.length >= 7 ? t.date.substring(0, 7) : t.date;
    totals[month] = (totals[month] ?? 0) + t.amount;
  }
  final entries = totals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.length <= 6 ? entries : entries.sublist(entries.length - 6);
}
