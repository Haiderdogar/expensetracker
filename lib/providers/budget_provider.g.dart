// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Budgets)
final budgetsProvider = BudgetsProvider._();

final class BudgetsProvider
    extends $AsyncNotifierProvider<Budgets, List<BudgetModel>> {
  BudgetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetsHash();

  @$internal
  @override
  Budgets create() => Budgets();
}

String _$budgetsHash() => r'b330d08ad87172570b5db9ae33467c6d95f6ef42';

abstract class _$Budgets extends $AsyncNotifier<List<BudgetModel>> {
  FutureOr<List<BudgetModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BudgetModel>>, List<BudgetModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BudgetModel>>, List<BudgetModel>>,
              AsyncValue<List<BudgetModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(monthBudgetProgress)
final monthBudgetProgressProvider = MonthBudgetProgressFamily._();

final class MonthBudgetProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BudgetProgress>>,
          List<BudgetProgress>,
          FutureOr<List<BudgetProgress>>
        >
    with
        $FutureModifier<List<BudgetProgress>>,
        $FutureProvider<List<BudgetProgress>> {
  MonthBudgetProgressProvider._({
    required MonthBudgetProgressFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'monthBudgetProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthBudgetProgressHash();

  @override
  String toString() {
    return r'monthBudgetProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<BudgetProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BudgetProgress>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthBudgetProgress(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthBudgetProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthBudgetProgressHash() =>
    r'847e08ee92649917a22dd0dfbbb941463f6d486a';

final class MonthBudgetProgressFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BudgetProgress>>, DateTime> {
  MonthBudgetProgressFamily._()
    : super(
        retry: null,
        name: r'monthBudgetProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MonthBudgetProgressProvider call(DateTime month) =>
      MonthBudgetProgressProvider._(argument: month, from: this);

  @override
  String toString() => r'monthBudgetProgressProvider';
}

@ProviderFor(currentMonthBudgetProgress)
final currentMonthBudgetProgressProvider =
    CurrentMonthBudgetProgressProvider._();

final class CurrentMonthBudgetProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BudgetProgress>>,
          List<BudgetProgress>,
          FutureOr<List<BudgetProgress>>
        >
    with
        $FutureModifier<List<BudgetProgress>>,
        $FutureProvider<List<BudgetProgress>> {
  CurrentMonthBudgetProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthBudgetProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthBudgetProgressHash();

  @$internal
  @override
  $FutureProviderElement<List<BudgetProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BudgetProgress>> create(Ref ref) {
    return currentMonthBudgetProgress(ref);
  }
}

String _$currentMonthBudgetProgressHash() =>
    r'9bf316fd97678f86c387d11ec84173fbd34a575e';
