import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';

part 'backup_provider.g.dart';

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
