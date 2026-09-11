import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final selectedBudgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final addBudgetCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);
final addBudgetAmountProvider = StateProvider.autoDispose<String>((ref) => '');
final addBudgetLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
