// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_shell_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppShellNavigationIndex)
final appShellNavigationIndexProvider = AppShellNavigationIndexProvider._();

final class AppShellNavigationIndexProvider
    extends $NotifierProvider<AppShellNavigationIndex, int> {
  AppShellNavigationIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appShellNavigationIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appShellNavigationIndexHash();

  @$internal
  @override
  AppShellNavigationIndex create() => AppShellNavigationIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$appShellNavigationIndexHash() =>
    r'cc18ca49125613d16423bd61854a2d231f41daf5';

abstract class _$AppShellNavigationIndex extends $Notifier<int> {
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

@ProviderFor(AppShellVisitedIndexes)
final appShellVisitedIndexesProvider = AppShellVisitedIndexesProvider._();

final class AppShellVisitedIndexesProvider
    extends $NotifierProvider<AppShellVisitedIndexes, Set<int>> {
  AppShellVisitedIndexesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appShellVisitedIndexesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appShellVisitedIndexesHash();

  @$internal
  @override
  AppShellVisitedIndexes create() => AppShellVisitedIndexes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$appShellVisitedIndexesHash() =>
    r'f1ae98e9209a544234e27440edbc68128eaee8ed';

abstract class _$AppShellVisitedIndexes extends $Notifier<Set<int>> {
  Set<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<int>, Set<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<int>, Set<int>>,
              Set<int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AppShellLogoutInProgress)
final appShellLogoutInProgressProvider = AppShellLogoutInProgressProvider._();

final class AppShellLogoutInProgressProvider
    extends $NotifierProvider<AppShellLogoutInProgress, bool> {
  AppShellLogoutInProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appShellLogoutInProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appShellLogoutInProgressHash();

  @$internal
  @override
  AppShellLogoutInProgress create() => AppShellLogoutInProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appShellLogoutInProgressHash() =>
    r'9538e82942438638dd724e2ebd94e8824b7bfc0e';

abstract class _$AppShellLogoutInProgress extends $Notifier<bool> {
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

@ProviderFor(appShellProfile)
final appShellProfileProvider = AppShellProfileProvider._();

final class AppShellProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppShellProfile>,
          AppShellProfile,
          FutureOr<AppShellProfile>
        >
    with $FutureModifier<AppShellProfile>, $FutureProvider<AppShellProfile> {
  AppShellProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appShellProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appShellProfileHash();

  @$internal
  @override
  $FutureProviderElement<AppShellProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppShellProfile> create(Ref ref) {
    return appShellProfile(ref);
  }
}

String _$appShellProfileHash() => r'ba96d08def88beb58a20f254d700ffee719c80e7';
