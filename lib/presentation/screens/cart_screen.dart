import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maks_riverpod/presentation/providers/cart_provider.dart';
import 'package:maks_riverpod/presentation/providers/order_provider.dart';

// =============================================================================
// ДЕМО: ConsumerStatefulWidget — статeful виджет с доступом к Riverpod
// =============================================================================
// Используем когда нужны ОДНОВРЕМЕННО:
//   - локальный State (AnimationController, TextEditingController, фокус и т.д.)
//   - доступ к провайдерам Riverpod
//
// Пара классов: ConsumerStatefulWidget + ConsumerState<T>
// В ConsumerState ref доступен как поле — не нужно получать его в build().
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    // ==========================================================================
    // ДЕМО: ref.listen() — реакция на изменения провайдера БЕЗ перестройки UI
    // ==========================================================================
    // listen() подписывается на провайдер и вызывает коллбек при изменении.
    // Не вызывает rebuild виджета — только side-effect (показ снэкбара и т.д.).
    //
    // ВАЖНО: в Riverpod 3.x ref.listen() можно вызывать ТОЛЬКО внутри build().
    // Riverpod сам следит за жизненным циклом и отписывается при dispose.
    ref.listen<int>(cartItemCountProvider, (previousCount, newCount) {
      if (previousCount != null && newCount < previousCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар удалён из корзины'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () {
                // ref.read() в коллбеке
                ref.read(cartProvider.notifier).clear();
              },
              child: const Text('Очистить'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Корзина пуста', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  leading: Text(
                    item.product.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(item.product.name),
                  subtitle: Text(
                    '${item.product.price.toStringAsFixed(0)} ₽ × ${item.quantity}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .decrementQuantity(item.product.id),
                      ),
                      Text(
                        '${item.quantity}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .incrementQuantity(item.product.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Итого:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${total.toStringAsFixed(0)} ₽',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _placeOrder(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Оформить заказ'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _placeOrder(BuildContext context) {
    final orderId = DateTime.now().millisecondsSinceEpoch.toString().substring(
      7,
    );
    ref.read(activeOrderIdProvider.notifier).setOrderId(orderId);

    // ==========================================================================
    // context.push() с именованным параметром в пути
    // ==========================================================================
    // /cart/order/:orderId — вложенный маршрут внутри ветки /cart.
    // Остаёмся внутри той же вкладки bottom nav bar.
    context.push('/cart/order/$orderId');
  }
}
