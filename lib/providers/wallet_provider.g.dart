// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeWalletName)
final activeWalletNameProvider = ActiveWalletNameProvider._();

final class ActiveWalletNameProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  ActiveWalletNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWalletNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWalletNameHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return activeWalletName(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$activeWalletNameHash() => r'74f9e4cb4d4746ca755c6b2d773484479e75c746';

@ProviderFor(Wallets)
final walletsProvider = WalletsProvider._();

final class WalletsProvider
    extends $AsyncNotifierProvider<Wallets, List<WalletModel>> {
  WalletsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletsHash();

  @$internal
  @override
  Wallets create() => Wallets();
}

String _$walletsHash() => r'f00766fffc0f65af471186755e4d9d0a9b8e5876';

abstract class _$Wallets extends $AsyncNotifier<List<WalletModel>> {
  FutureOr<List<WalletModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<WalletModel>>, List<WalletModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<WalletModel>>, List<WalletModel>>,
              AsyncValue<List<WalletModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(totalBalance)
final totalBalanceProvider = TotalBalanceProvider._();

final class TotalBalanceProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  TotalBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalBalanceHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return totalBalance(ref);
  }
}

String _$totalBalanceHash() => r'43349ef2e156307f34442e8610f2f13dadbbbf4e';
