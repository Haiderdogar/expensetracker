import 'package:flutter_riverpod/legacy.dart';

const recentTransactionFilterOptions = <String>[
  'Today',
  '3 Days',
  '1 Week',
  '1 Month',
  'All',
];

final recentTransactionFilterProvider = StateProvider.autoDispose<String>(
  (ref) => 'All',
);
