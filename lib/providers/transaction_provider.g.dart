// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Transactions)
final transactionsProvider = TransactionsProvider._();

final class TransactionsProvider
    extends $AsyncNotifierProvider<Transactions, List<TransactionModel>> {
  TransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsHash();

  @$internal
  @override
  Transactions create() => Transactions();
}

String _$transactionsHash() => r'ed5110abde98062d35247997de6503b9b527a833';

abstract class _$Transactions extends $AsyncNotifier<List<TransactionModel>> {
  FutureOr<List<TransactionModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<TransactionModel>>, List<TransactionModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TransactionModel>>,
                List<TransactionModel>
              >,
              AsyncValue<List<TransactionModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(recentTransactions)
final recentTransactionsProvider = RecentTransactionsProvider._();

final class RecentTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransactionModel>>,
          List<TransactionModel>,
          FutureOr<List<TransactionModel>>
        >
    with
        $FutureModifier<List<TransactionModel>>,
        $FutureProvider<List<TransactionModel>> {
  RecentTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TransactionModel>> create(Ref ref) {
    return recentTransactions(ref);
  }
}

String _$recentTransactionsHash() =>
    r'94ad107e148472d6c79271777d38fb6ff6bfaae4';

@ProviderFor(totalIncome)
final totalIncomeProvider = TotalIncomeProvider._();

final class TotalIncomeProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  TotalIncomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalIncomeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalIncomeHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return totalIncome(ref);
  }
}

String _$totalIncomeHash() => r'ddb8acc8f8d7eaac4935697fd719706ff23b5056';

@ProviderFor(totalExpense)
final totalExpenseProvider = TotalExpenseProvider._();

final class TotalExpenseProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  TotalExpenseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalExpenseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalExpenseHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return totalExpense(ref);
  }
}

String _$totalExpenseHash() => r'827a3ce3c24eda8996a242de8f678b7e0b34f67d';

@ProviderFor(filteredTransactions)
final filteredTransactionsProvider = FilteredTransactionsFamily._();

final class FilteredTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransactionModel>>,
          List<TransactionModel>,
          FutureOr<List<TransactionModel>>
        >
    with
        $FutureModifier<List<TransactionModel>>,
        $FutureProvider<List<TransactionModel>> {
  FilteredTransactionsProvider._({
    required FilteredTransactionsFamily super.from,
    required ({
      String? type,
      String? search,
      List<String>? categories,
      DateTime? month,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'filteredTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredTransactionsHash();

  @override
  String toString() {
    return r'filteredTransactionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TransactionModel>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String? type,
              String? search,
              List<String>? categories,
              DateTime? month,
            });
    return filteredTransactions(
      ref,
      type: argument.type,
      search: argument.search,
      categories: argument.categories,
      month: argument.month,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredTransactionsHash() =>
    r'9efa81b4d81cc3ce4f0edc5c774b0cafcb9544ec';

final class FilteredTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TransactionModel>>,
          ({
            String? type,
            String? search,
            List<String>? categories,
            DateTime? month,
          })
        > {
  FilteredTransactionsFamily._()
    : super(
        retry: null,
        name: r'filteredTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredTransactionsProvider call({
    String? type,
    String? search,
    List<String>? categories,
    DateTime? month,
  }) => FilteredTransactionsProvider._(
    argument: (
      type: type,
      search: search,
      categories: categories,
      month: month,
    ),
    from: this,
  );

  @override
  String toString() => r'filteredTransactionsProvider';
}

@ProviderFor(currentMonthIncome)
final currentMonthIncomeProvider = CurrentMonthIncomeProvider._();

final class CurrentMonthIncomeProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  CurrentMonthIncomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthIncomeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthIncomeHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return currentMonthIncome(ref);
  }
}

String _$currentMonthIncomeHash() =>
    r'1f33cde8baec5a73329c74422c86fb024323b37f';

@ProviderFor(currentMonthExpense)
final currentMonthExpenseProvider = CurrentMonthExpenseProvider._();

final class CurrentMonthExpenseProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  CurrentMonthExpenseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthExpenseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthExpenseHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return currentMonthExpense(ref);
  }
}

String _$currentMonthExpenseHash() =>
    r'5c8f079e7405357febe62adb49c25d82c7d0db97';

@ProviderFor(dashboardDisplayBalance)
final dashboardDisplayBalanceProvider = DashboardDisplayBalanceProvider._();

final class DashboardDisplayBalanceProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  DashboardDisplayBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardDisplayBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardDisplayBalanceHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return dashboardDisplayBalance(ref);
  }
}

String _$dashboardDisplayBalanceHash() =>
    r'20c91cfc05b50bef1728b5042215d7246182d9e0';
