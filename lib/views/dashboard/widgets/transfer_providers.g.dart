// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransferDraftNotifier)
final transferDraftProvider = TransferDraftNotifierProvider._();

final class TransferDraftNotifierProvider
    extends $NotifierProvider<TransferDraftNotifier, TransferDraft> {
  TransferDraftNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferDraftNotifierHash();

  @$internal
  @override
  TransferDraftNotifier create() => TransferDraftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferDraft>(value),
    );
  }
}

String _$transferDraftNotifierHash() =>
    r'a07522e822457652b3d2e6c3f2a27395d68ae44f';

abstract class _$TransferDraftNotifier extends $Notifier<TransferDraft> {
  TransferDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransferDraft, TransferDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransferDraft, TransferDraft>,
              TransferDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
