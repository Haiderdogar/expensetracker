// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionSearchTextController)
final transactionSearchTextControllerProvider =
    TransactionSearchTextControllerProvider._();

final class TransactionSearchTextControllerProvider
    extends
        $FunctionalProvider<
          TextEditingController,
          TextEditingController,
          TextEditingController
        >
    with $Provider<TextEditingController> {
  TransactionSearchTextControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionSearchTextControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$transactionSearchTextControllerHash();

  @$internal
  @override
  $ProviderElement<TextEditingController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TextEditingController create(Ref ref) {
    return transactionSearchTextController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TextEditingController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TextEditingController>(value),
    );
  }
}

String _$transactionSearchTextControllerHash() =>
    r'3b5be49790f68ef36f1f9abcb8412d7905b8877a';

@ProviderFor(TransactionSearch)
final transactionSearchProvider = TransactionSearchProvider._();

final class TransactionSearchProvider
    extends $NotifierProvider<TransactionSearch, String> {
  TransactionSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionSearchHash();

  @$internal
  @override
  TransactionSearch create() => TransactionSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$transactionSearchHash() => r'b563518529423c5418a2f0e838014c60c2f99242';

abstract class _$TransactionSearch extends $Notifier<String> {
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

@ProviderFor(TransactionTypeFilter)
final transactionTypeFilterProvider = TransactionTypeFilterProvider._();

final class TransactionTypeFilterProvider
    extends $NotifierProvider<TransactionTypeFilter, String?> {
  TransactionTypeFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionTypeFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionTypeFilterHash();

  @$internal
  @override
  TransactionTypeFilter create() => TransactionTypeFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$transactionTypeFilterHash() =>
    r'3c5a178fd1383dba2fd5091660fdfcd3e8722469';

abstract class _$TransactionTypeFilter extends $Notifier<String?> {
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

@ProviderFor(SelectedCategoryFilters)
final selectedCategoryFiltersProvider = SelectedCategoryFiltersProvider._();

final class SelectedCategoryFiltersProvider
    extends $NotifierProvider<SelectedCategoryFilters, List<String>?> {
  SelectedCategoryFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCategoryFiltersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCategoryFiltersHash();

  @$internal
  @override
  SelectedCategoryFilters create() => SelectedCategoryFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>?>(value),
    );
  }
}

String _$selectedCategoryFiltersHash() =>
    r'9267444da5d1cea0fc88d0ad3e1e32a32f79af5c';

abstract class _$SelectedCategoryFilters extends $Notifier<List<String>?> {
  List<String>? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>?, List<String>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>?, List<String>?>,
              List<String>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TransactionCategoryFilterDraft)
final transactionCategoryFilterDraftProvider =
    TransactionCategoryFilterDraftProvider._();

final class TransactionCategoryFilterDraftProvider
    extends $NotifierProvider<TransactionCategoryFilterDraft, List<String>> {
  TransactionCategoryFilterDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionCategoryFilterDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionCategoryFilterDraftHash();

  @$internal
  @override
  TransactionCategoryFilterDraft create() => TransactionCategoryFilterDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$transactionCategoryFilterDraftHash() =>
    r'e93d3ba25483042aff50a71de7277d06e79c756b';

abstract class _$TransactionCategoryFilterDraft
    extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TransactionInitialType)
final transactionInitialTypeProvider = TransactionInitialTypeProvider._();

final class TransactionInitialTypeProvider
    extends $NotifierProvider<TransactionInitialType, String> {
  TransactionInitialTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionInitialTypeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionInitialTypeHash();

  @$internal
  @override
  TransactionInitialType create() => TransactionInitialType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$transactionInitialTypeHash() =>
    r'be7e115df4560b09b404f0f1ef01e83c1572aa59';

abstract class _$TransactionInitialType extends $Notifier<String> {
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

@ProviderFor(TransactionFormNotifier)
final transactionFormProvider = TransactionFormNotifierFamily._();

final class TransactionFormNotifierProvider
    extends $NotifierProvider<TransactionFormNotifier, TransactionFormDraft> {
  TransactionFormNotifierProvider._({
    required TransactionFormNotifierFamily super.from,
    required TransactionModel? super.argument,
  }) : super(
         retry: null,
         name: r'transactionFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionFormNotifierHash();

  @override
  String toString() {
    return r'transactionFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TransactionFormNotifier create() => TransactionFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFormDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionFormDraft>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionFormNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionFormNotifierHash() =>
    r'e6ec14bcf8efc655d0850e8a032dfaa3fc960851';

final class TransactionFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionFormNotifier,
          TransactionFormDraft,
          TransactionFormDraft,
          TransactionFormDraft,
          TransactionModel?
        > {
  TransactionFormNotifierFamily._()
    : super(
        retry: null,
        name: r'transactionFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionFormNotifierProvider call(TransactionModel? transaction) =>
      TransactionFormNotifierProvider._(argument: transaction, from: this);

  @override
  String toString() => r'transactionFormProvider';
}

abstract class _$TransactionFormNotifier
    extends $Notifier<TransactionFormDraft> {
  late final _$args = ref.$arg as TransactionModel?;
  TransactionModel? get transaction => _$args;

  TransactionFormDraft build(TransactionModel? transaction);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionFormDraft, TransactionFormDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionFormDraft, TransactionFormDraft>,
              TransactionFormDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(UnifiedCategoryFilterDraft)
final unifiedCategoryFilterDraftProvider =
    UnifiedCategoryFilterDraftProvider._();

final class UnifiedCategoryFilterDraftProvider
    extends $NotifierProvider<UnifiedCategoryFilterDraft, Set<String>> {
  UnifiedCategoryFilterDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unifiedCategoryFilterDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unifiedCategoryFilterDraftHash();

  @$internal
  @override
  UnifiedCategoryFilterDraft create() => UnifiedCategoryFilterDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$unifiedCategoryFilterDraftHash() =>
    r'9d302d602ef9e11d289754fea68ff0f59b5fe237';

abstract class _$UnifiedCategoryFilterDraft extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
