// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_products_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoriteProducts)
final favoriteProductsProvider = FavoriteProductsProvider._();

final class FavoriteProductsProvider
    extends $AsyncNotifierProvider<FavoriteProducts, List<String>> {
  FavoriteProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteProductsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteProductsHash();

  @$internal
  @override
  FavoriteProducts create() => FavoriteProducts();
}

String _$favoriteProductsHash() => r'95575e9584e5084f5af71d46e3c9cf4b38ac449a';

abstract class _$FavoriteProducts extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(IsFavoriteProduct)
final isFavoriteProductProvider = IsFavoriteProductFamily._();

final class IsFavoriteProductProvider
    extends $AsyncNotifierProvider<IsFavoriteProduct, bool> {
  IsFavoriteProductProvider._({
    required IsFavoriteProductFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavoriteProductProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavoriteProductHash();

  @override
  String toString() {
    return r'isFavoriteProductProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IsFavoriteProduct create() => IsFavoriteProduct();

  @override
  bool operator ==(Object other) {
    return other is IsFavoriteProductProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoriteProductHash() => r'c0fa8a1c2443b4443926123b5218f2c3893edda3';

final class IsFavoriteProductFamily extends $Family
    with
        $ClassFamilyOverride<
          IsFavoriteProduct,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
        > {
  IsFavoriteProductFamily._()
    : super(
        retry: null,
        name: r'isFavoriteProductProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsFavoriteProductProvider call(String productId) =>
      IsFavoriteProductProvider._(argument: productId, from: this);

  @override
  String toString() => r'isFavoriteProductProvider';
}

abstract class _$IsFavoriteProduct extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as String;
  String get productId => _$args;

  FutureOr<bool> build(String productId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
