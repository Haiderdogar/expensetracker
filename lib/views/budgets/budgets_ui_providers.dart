import 'package:flutter_riverpod/legacy.dart';

final addBudgetCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);
final addBudgetAmountProvider = StateProvider.autoDispose<String>((ref) => '');
final addBudgetLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
