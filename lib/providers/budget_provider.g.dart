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

String _$budgetsHash() => r'e1ffa476adf1d606f4108d758e20d184d808e71c';

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
    r'fadae3230d22db8151be7f97d9148eb6c9254f51';
