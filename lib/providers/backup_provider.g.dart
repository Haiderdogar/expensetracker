// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(expenseByCategory)
final expenseByCategoryProvider = ExpenseByCategoryProvider._();

final class ExpenseByCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double>>,
          Map<String, double>,
          FutureOr<Map<String, double>>
        >
    with
        $FutureModifier<Map<String, double>>,
        $FutureProvider<Map<String, double>> {
  ExpenseByCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseByCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseByCategoryHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, double>> create(Ref ref) {
    return expenseByCategory(ref);
  }
}

String _$expenseByCategoryHash() => r'19026361dbad13df0fd7c10e87b93864be088fc1';

@ProviderFor(monthlySpendingTrend)
final monthlySpendingTrendProvider = MonthlySpendingTrendProvider._();

final class MonthlySpendingTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapEntry<String, double>>>,
          List<MapEntry<String, double>>,
          FutureOr<List<MapEntry<String, double>>>
        >
    with
        $FutureModifier<List<MapEntry<String, double>>>,
        $FutureProvider<List<MapEntry<String, double>>> {
  MonthlySpendingTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlySpendingTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlySpendingTrendHash();

  @$internal
  @override
  $FutureProviderElement<List<MapEntry<String, double>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapEntry<String, double>>> create(Ref ref) {
    return monthlySpendingTrend(ref);
  }
}

String _$monthlySpendingTrendHash() =>
    r'1918126581b0991d32a87be70cb37e721eb0710e';
