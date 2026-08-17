// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$walletsHash() => r'5bf7e63fcee4defb2de4f796ed0381bfa600a6cb';

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
