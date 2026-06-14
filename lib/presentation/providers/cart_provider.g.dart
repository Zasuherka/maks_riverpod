// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Cart)
final cartProvider = CartProvider._();

final class CartProvider extends $NotifierProvider<Cart, List<CartItem>> {
  CartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartHash();

  @$internal
  @override
  Cart create() => Cart();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CartItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CartItem>>(value),
    );
  }
}

String _$cartHash() => r'8aaec10ae62b54858970a99b2e17f402723f2cf2';

abstract class _$Cart extends $Notifier<List<CartItem>> {
  List<CartItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<CartItem>, List<CartItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<CartItem>, List<CartItem>>,
              List<CartItem>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(cartTotal)
final cartTotalProvider = CartTotalProvider._();

final class CartTotalProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  CartTotalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartTotalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartTotalHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return cartTotal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$cartTotalHash() => r'348c7370dfb2820cd1e7016ea2cc41035cac5033';

@ProviderFor(cartItemCount)
final cartItemCountProvider = CartItemCountProvider._();

final class CartItemCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  CartItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartItemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartItemCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return cartItemCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$cartItemCountHash() => r'b6e377cde02c574c62745a0dcbea6f2e8f647ce1';

@ProviderFor(isProductInCart)
final isProductInCartProvider = IsProductInCartFamily._();

final class IsProductInCartProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsProductInCartProvider._({
    required IsProductInCartFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isProductInCartProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isProductInCartHash();

  @override
  String toString() {
    return r'isProductInCartProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isProductInCart(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsProductInCartProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isProductInCartHash() => r'3e86df5c1d250ad38f74f01ec7c8726c71571a1b';

final class IsProductInCartFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsProductInCartFamily._()
    : super(
        retry: null,
        name: r'isProductInCartProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsProductInCartProvider call(String productId) =>
      IsProductInCartProvider._(argument: productId, from: this);

  @override
  String toString() => r'isProductInCartProvider';
}
