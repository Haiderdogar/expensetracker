// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppStartupController)
final appStartupControllerProvider = AppStartupControllerProvider._();

final class AppStartupControllerProvider
    extends $AsyncNotifierProvider<AppStartupController, AppFlow> {
  AppStartupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupControllerHash();

  @$internal
  @override
  AppStartupController create() => AppStartupController();
}

String _$appStartupControllerHash() =>
    r'd1655140926174bfcb53e692378fb18951d0ee50';

abstract class _$AppStartupController extends $AsyncNotifier<AppFlow> {
  FutureOr<AppFlow> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppFlow>, AppFlow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppFlow>, AppFlow>,
              AsyncValue<AppFlow>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
