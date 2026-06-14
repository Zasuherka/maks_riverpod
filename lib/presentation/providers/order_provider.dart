import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_provider.g.dart';

// Статусы заказа
enum OrderStatus {
  accepted('Заказ принят', '✅'),
  preparing('Собирается', '📦'),
  assembling('Проверяется', '🔍'),
  ready('Готов к выдаче', '🎉');

  const OrderStatus(this.label, this.emoji);

  final String label;
  final String emoji;
}

// =============================================================================
// ДЕМО: StreamProvider + family параметр
// =============================================================================
// Функция, возвращающая Stream<T> — генерирует StreamProvider.
// При watch() виджет получает AsyncValue<T>, как и с Future.
//
// family: параметр orderId делает это "family" провайдером —
// ref.watch(orderStatusProvider('order-123')) создаёт отдельный
// экземпляр провайдера для каждого уникального orderId.
//
// autoDispose по умолчанию (@riverpod) — поток автоматически отменится
// когда экран статуса заказа закроется (виджет покинет дерево).
// Это предотвращает утечки памяти при работе с потоками.
@riverpod
Stream<OrderStatus> orderStatus(Ref ref, String orderId) async* {
  // async* — генератор потока данных. yield — отправить значение в поток.

  yield OrderStatus.accepted;
  await Future.delayed(const Duration(seconds: 2));

  yield OrderStatus.preparing;
  await Future.delayed(const Duration(seconds: 3));

  yield OrderStatus.assembling;
  await Future.delayed(const Duration(seconds: 2));

  yield OrderStatus.ready;
}

// =============================================================================
// ДЕМО: Простой провайдер для хранения ID последнего заказа
// =============================================================================
// Аналог StateProvider из старых версий Riverpod.
// keepAlive: true — ID заказа должен сохраняться при навигации.
@Riverpod(keepAlive: true)
class ActiveOrderId extends _$ActiveOrderId {
  @override
  String? build() => null;

  void setOrderId(String id) => state = id;
  void clear() => state = null;
}
