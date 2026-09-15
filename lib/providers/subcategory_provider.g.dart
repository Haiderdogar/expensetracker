// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subcategory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subcategories)
final subcategoriesProvider = SubcategoriesFamily._();

final class SubcategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SubcategoryModel>>,
          List<SubcategoryModel>,
          FutureOr<List<SubcategoryModel>>
        >
    with
        $FutureModifier<List<SubcategoryModel>>,
        $FutureProvider<List<SubcategoryModel>> {
  SubcategoriesProvider._({
    required SubcategoriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'subcategoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subcategoriesHash();

  @override
  String toString() {
    return r'subcategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SubcategoryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SubcategoryModel>> create(Ref ref) {
    final argument = this.argument as String;
    return subcategories(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SubcategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subcategoriesHash() => r'1a82bf7a25bfd900de29d77520cda3a46de221d9';

final class SubcategoriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SubcategoryModel>>, String> {
  SubcategoriesFamily._()
    : super(
        retry: null,
        name: r'subcategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SubcategoriesProvider call(String categoryId) =>
      SubcategoriesProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'subcategoriesProvider';
}
