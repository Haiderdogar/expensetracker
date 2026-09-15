// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthUiStateNotifier)
final authUiStateProvider = AuthUiStateNotifierFamily._();

final class AuthUiStateNotifierProvider
    extends $NotifierProvider<AuthUiStateNotifier, AuthUiState> {
  AuthUiStateNotifierProvider._({
    required AuthUiStateNotifierFamily super.from,
    required AuthScreenConfig super.argument,
  }) : super(
         retry: null,
         name: r'authUiStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authUiStateNotifierHash();

  @override
  String toString() {
    return r'authUiStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AuthUiStateNotifier create() => AuthUiStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthUiState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthUiStateNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authUiStateNotifierHash() =>
    r'73f0a6bedbab0081b473053bcf10b99efe48355e';

final class AuthUiStateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AuthUiStateNotifier,
          AuthUiState,
          AuthUiState,
          AuthUiState,
          AuthScreenConfig
        > {
  AuthUiStateNotifierFamily._()
    : super(
        retry: null,
        name: r'authUiStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthUiStateNotifierProvider call(AuthScreenConfig config) =>
      AuthUiStateNotifierProvider._(argument: config, from: this);

  @override
  String toString() => r'authUiStateProvider';
}

abstract class _$AuthUiStateNotifier extends $Notifier<AuthUiState> {
  late final _$args = ref.$arg as AuthScreenConfig;
  AuthScreenConfig get config => _$args;

  AuthUiState build(AuthScreenConfig config);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthUiState, AuthUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthUiState, AuthUiState>,
              AuthUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(authPinController)
final authPinControllerProvider = AuthPinControllerFamily._();

final class AuthPinControllerProvider
    extends
        $FunctionalProvider<
          TextEditingController,
          TextEditingController,
          TextEditingController
        >
    with $Provider<TextEditingController> {
  AuthPinControllerProvider._({
    required AuthPinControllerFamily super.from,
    required AuthScreenConfig super.argument,
  }) : super(
         retry: null,
         name: r'authPinControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authPinControllerHash();

  @override
  String toString() {
    return r'authPinControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TextEditingController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TextEditingController create(Ref ref) {
    final argument = this.argument as AuthScreenConfig;
    return authPinController(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TextEditingController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TextEditingController>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthPinControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authPinControllerHash() => r'9605c7e4c7cef5c8e9a9d377bd28c9635e05f785';

final class AuthPinControllerFamily extends $Family
    with $FunctionalFamilyOverride<TextEditingController, AuthScreenConfig> {
  AuthPinControllerFamily._()
    : super(
        retry: null,
        name: r'authPinControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthPinControllerProvider call(AuthScreenConfig config) =>
      AuthPinControllerProvider._(argument: config, from: this);

  @override
  String toString() => r'authPinControllerProvider';
}

@ProviderFor(authPinFocusNode)
final authPinFocusNodeProvider = AuthPinFocusNodeFamily._();

final class AuthPinFocusNodeProvider
    extends $FunctionalProvider<FocusNode, FocusNode, FocusNode>
    with $Provider<FocusNode> {
  AuthPinFocusNodeProvider._({
    required AuthPinFocusNodeFamily super.from,
    required AuthScreenConfig super.argument,
  }) : super(
         retry: null,
         name: r'authPinFocusNodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authPinFocusNodeHash();

  @override
  String toString() {
    return r'authPinFocusNodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FocusNode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FocusNode create(Ref ref) {
    final argument = this.argument as AuthScreenConfig;
    return authPinFocusNode(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusNode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusNode>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthPinFocusNodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authPinFocusNodeHash() => r'a8ea619fa716dfe91cee7e344f869151476f82e0';

final class AuthPinFocusNodeFamily extends $Family
    with $FunctionalFamilyOverride<FocusNode, AuthScreenConfig> {
  AuthPinFocusNodeFamily._()
    : super(
        retry: null,
        name: r'authPinFocusNodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthPinFocusNodeProvider call(AuthScreenConfig config) =>
      AuthPinFocusNodeProvider._(argument: config, from: this);

  @override
  String toString() => r'authPinFocusNodeProvider';
}
