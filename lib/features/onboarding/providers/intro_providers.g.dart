// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the current onboarding page.
///
/// 0 = first page
/// 1 = second page
/// 2 = third page

@ProviderFor(IntroPageIndex)
final introPageIndexProvider = IntroPageIndexProvider._();

/// Manages the current onboarding page.
///
/// 0 = first page
/// 1 = second page
/// 2 = third page
final class IntroPageIndexProvider
    extends $NotifierProvider<IntroPageIndex, int> {
  /// Manages the current onboarding page.
  ///
  /// 0 = first page
  /// 1 = second page
  /// 2 = third page
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

String _$introPageIndexHash() => r'c7ae5891c6af6da39b1177c2a84bbcc1f407839f';

/// Manages the current onboarding page.
///
/// 0 = first page
/// 1 = second page
/// 2 = third page

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

/// Manages the loading state while onboarding
/// completion is being saved.

@ProviderFor(IntroCompleting)
final introCompletingProvider = IntroCompletingProvider._();

/// Manages the loading state while onboarding
/// completion is being saved.
final class IntroCompletingProvider
    extends $NotifierProvider<IntroCompleting, bool> {
  /// Manages the loading state while onboarding
  /// completion is being saved.
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

String _$introCompletingHash() => r'1e6740ca7f79f682b077c33ab899ce20bba80c9e';

/// Manages the loading state while onboarding
/// completion is being saved.

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

/// Provides the PageController used by the onboarding PageView.
///
/// The controller is disposed automatically when the
/// generated provider is disposed.

@ProviderFor(introPageController)
final introPageControllerProvider = IntroPageControllerProvider._();

/// Provides the PageController used by the onboarding PageView.
///
/// The controller is disposed automatically when the
/// generated provider is disposed.

final class IntroPageControllerProvider
    extends $FunctionalProvider<PageController, PageController, PageController>
    with $Provider<PageController> {
  /// Provides the PageController used by the onboarding PageView.
  ///
  /// The controller is disposed automatically when the
  /// generated provider is disposed.
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
