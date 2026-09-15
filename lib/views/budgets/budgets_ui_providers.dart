import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'budgets_ui_providers.g.dart';

@Riverpod(keepAlive: true)
class SelectedBudgetMonth extends _$SelectedBudgetMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  @override
  set state(DateTime value) => super.state = value;
}

@riverpod
class AddBudgetCategory extends _$AddBudgetCategory {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

@riverpod
class AddBudgetAmount extends _$AddBudgetAmount {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

@riverpod
class AddBudgetLoading extends _$AddBudgetLoading {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
}
