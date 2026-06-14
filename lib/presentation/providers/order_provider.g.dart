// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orderStatus)
final orderStatusProvider = OrderStatusFamily._();

final class OrderStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderStatus>,
          OrderStatus,
          Stream<OrderStatus>
        >
    with $FutureModifier<OrderStatus>, $StreamProvider<OrderStatus> {
  OrderStatusProvider._({
    required OrderStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderStatusHash();

  @override
  String toString() {
    return r'orderStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OrderStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OrderStatus> create(Ref ref) {
    final argument = this.argument as String;
    return orderStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderStatusHash() => r'a577b76157b7bad63e98f5f16b7fc1c791d8c35d';

final class OrderStatusFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OrderStatus>, String> {
  OrderStatusFamily._()
    : super(
        retry: null,
        name: r'orderStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderStatusProvider call(String orderId) =>
      OrderStatusProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderStatusProvider';
}

@ProviderFor(ActiveOrderId)
final activeOrderIdProvider = ActiveOrderIdProvider._();

final class ActiveOrderIdProvider
    extends $NotifierProvider<ActiveOrderId, String?> {
  ActiveOrderIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeOrderIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeOrderIdHash();

  @$internal
  @override
  ActiveOrderId create() => ActiveOrderId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeOrderIdHash() => r'7193c3049b9f024b4853e1bb934f928fe4b72bcc';

abstract class _$ActiveOrderId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
