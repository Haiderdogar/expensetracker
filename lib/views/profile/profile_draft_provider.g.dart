// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileDraftNotifier)
final profileDraftProvider = ProfileDraftNotifierProvider._();

final class ProfileDraftNotifierProvider
    extends $NotifierProvider<ProfileDraftNotifier, ProfileDraft> {
  ProfileDraftNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileDraftNotifierHash();

  @$internal
  @override
  ProfileDraftNotifier create() => ProfileDraftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileDraft>(value),
    );
  }
}

String _$profileDraftNotifierHash() =>
    r'4c6394e84ff19985a2fad5c6d58c758860c3c659';

abstract class _$ProfileDraftNotifier extends $Notifier<ProfileDraft> {
  ProfileDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileDraft, ProfileDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileDraft, ProfileDraft>,
              ProfileDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
