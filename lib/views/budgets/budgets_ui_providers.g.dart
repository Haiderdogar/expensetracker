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
    r'503eab1cdcb0d9e97b18601387fff9b5c51d77bf';

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

String _$addBudgetCategoryHash() => r'80196010a164864a5676a9d57e2ba9d8ba09fb7e';

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

String _$addBudgetAmountHash() => r'eb16f1b6499a8dffc4413da9aa0fe1ec5a05a487';

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

String _$addBudgetLoadingHash() => r'8c12eaa22c2fbbe95e1b2a6bfe74b79d69eac939';

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
