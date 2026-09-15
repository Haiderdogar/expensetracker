// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IntroPageIndex)
final introPageIndexProvider = IntroPageIndexProvider._();

final class IntroPageIndexProvider
    extends $NotifierProvider<IntroPageIndex, int> {
  IntroPageIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'introPageIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$introPageIndexHash();

  @$internal
  @override
  IntroPageIndex create() => IntroPageIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$introPageIndexHash() => r'ee6d8c33fa61437c30c20aede7fb5cd894c29e41';

abstract class _$IntroPageIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(IntroCompleting)
final introCompletingProvider = IntroCompletingProvider._();

final class IntroCompletingProvider
    extends $NotifierProvider<IntroCompleting, bool> {
  IntroCompletingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'introCompletingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$introCompletingHash();

  @$internal
  @override
  IntroCompleting create() => IntroCompleting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$introCompletingHash() => r'07d57392c89726b89efe5ab407602a3651ad688f';

abstract class _$IntroCompleting extends $Notifier<bool> {
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

@ProviderFor(introPageController)
final introPageControllerProvider = IntroPageControllerProvider._();

final class IntroPageControllerProvider
    extends $FunctionalProvider<PageController, PageController, PageController>
    with $Provider<PageController> {
  IntroPageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'introPageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$introPageControllerHash();

  @$internal
  @override
  $ProviderElement<PageController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PageController create(Ref ref) {
    return introPageController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PageController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PageController>(value),
    );
  }
}

String _$introPageControllerHash() =>
    r'56f1d46615c57725f03298e6e1d877db0dc2cc1f';
