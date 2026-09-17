// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budgets_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedBudgetMonth)
final selectedBudgetMonthProvider = SelectedBudgetMonthProvider._();

final class SelectedBudgetMonthProvider
    extends $NotifierProvider<SelectedBudgetMonth, DateTime> {
  SelectedBudgetMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedBudgetMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedBudgetMonthHash();

  @$internal
  @override
  SelectedBudgetMonth create() => SelectedBudgetMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedBudgetMonthHash() =>
    r'146f55e77a28bd86eb98d2e1c46e75ae23d39505';

abstract class _$SelectedBudgetMonth extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AddBudgetCategory)
final addBudgetCategoryProvider = AddBudgetCategoryProvider._();

final class AddBudgetCategoryProvider
    extends $NotifierProvider<AddBudgetCategory, String?> {
  AddBudgetCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addBudgetCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addBudgetCategoryHash();

  @$internal
  @override
  AddBudgetCategory create() => AddBudgetCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$addBudgetCategoryHash() => r'23aaaf6b5bdca10d684a2ea721c0ce28bc000760';

abstract class _$AddBudgetCategory extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AddBudgetAmount)
final addBudgetAmountProvider = AddBudgetAmountProvider._();

final class AddBudgetAmountProvider
    extends $NotifierProvider<AddBudgetAmount, String> {
  AddBudgetAmountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addBudgetAmountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addBudgetAmountHash();

  @$internal
  @override
  AddBudgetAmount create() => AddBudgetAmount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$addBudgetAmountHash() => r'213314fb194d9dcfe2213788e557c31b064a76ba';

abstract class _$AddBudgetAmount extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AddBudgetLoading)
final addBudgetLoadingProvider = AddBudgetLoadingProvider._();

final class AddBudgetLoadingProvider
    extends $NotifierProvider<AddBudgetLoading, bool> {
  AddBudgetLoadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addBudgetLoadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addBudgetLoadingHash();

  @$internal
  @override
  AddBudgetLoading create() => AddBudgetLoading();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$addBudgetLoadingHash() => r'402f8e689ad96e7a41175cf4860ac3b5fc1d71c5';

abstract class _$AddBudgetLoading extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
