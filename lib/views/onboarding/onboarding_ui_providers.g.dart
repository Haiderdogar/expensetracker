// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingDraftNotifier)
final onboardingDraftProvider = OnboardingDraftNotifierProvider._();

final class OnboardingDraftNotifierProvider
    extends $NotifierProvider<OnboardingDraftNotifier, OnboardingDraft> {
  OnboardingDraftNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingDraftNotifierHash();

  @$internal
  @override
  OnboardingDraftNotifier create() => OnboardingDraftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingDraft>(value),
    );
  }
}

String _$onboardingDraftNotifierHash() =>
    r'b579bc45e7e8fae677dc48341ed47eac8e4e5767';

abstract class _$OnboardingDraftNotifier extends $Notifier<OnboardingDraft> {
  OnboardingDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OnboardingDraft, OnboardingDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingDraft, OnboardingDraft>,
              OnboardingDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
