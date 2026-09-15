import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_ui_providers.g.dart';

const recentTransactionFilterOptions = <String>[
  'Today',
  '3 Days',
  '1 Week',
  '1 Month',
  'All',
];

@riverpod
class RecentTransactionFilter extends _$RecentTransactionFilter {
  @override
  String build() => 'All';

  @override
  set state(String value) => super.state = value;
}

@Riverpod(keepAlive: true)
class DashboardBalanceHidden extends _$DashboardBalanceHidden {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
  void toggle() => state = !state;
}
