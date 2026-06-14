import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maks_riverpod/domain/models/product.dart';
import 'package:maks_riverpod/presentation/providers/cart_provider.dart';
import 'package:maks_riverpod/presentation/providers/favorite_products_provider.dart';

// =============================================================================
// ДЕМО: ConsumerWidget
// =============================================================================
// ConsumerWidget — аналог StatelessWidget, но с доступом к Riverpod через WidgetRef.
// Второй параметр build() — WidgetRef ref (в отличие от StatelessWidget).
// Виджет перестраивается только когда изменились слушаемые им провайдеры.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() — подписываемся на провайдер.
    // Виджет перестроится при изменении isProductInCartProvider для этого product.
    //
    // isProductInCartProvider — family провайдер: передаём id как аргумент.
    // Каждый ProductCard слушает только "свой" экземпляр провайдера.
    final isInCart = ref.watch(isProductInCartProvider(product.id));
    final isFavoriteAsync = ref.watch(isFavoriteProductProvider(product.id));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(product.emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
            Text(
              '${product.price.toStringAsFixed(0)} ₽',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: isInCart
                      ? _CartControls(productId: product.id)
                      : FilledButton.tonal(
                          onPressed: () {
                            // ref.read() — читаем провайдер БЕЗ подписки.
                            // Используется внутри коллбеков (onPressed, onTap и т.д.),
                            // где нам не нужна реактивность — просто вызвать метод.
                            ref.read(cartProvider.notifier).addProduct(product);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          child: const Text(
                            'В корзину',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(isFavoriteProductProvider(product.id).notifier)
                        .editFavorite(product.id);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: .circle,
                    ),
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: isFavoriteAsync.map(
                          error: (error) {
                            return _FavoriteIcon(
                              isFavorite: error.value ?? false,
                            );
                          },
                          loading: (loading) {
                            return CircularProgressIndicator();
                          },
                          data: (data) {
                            return _FavoriteIcon(isFavorite: data.value);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteIcon extends StatelessWidget {
  final bool isFavorite;
  const _FavoriteIcon({required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    return Icon(isFavorite ? Icons.favorite : Icons.favorite_border);
  }
}

// Виджет управления количеством в корзине
class _CartControls extends ConsumerWidget {
  const _CartControls({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final item = cart.firstWhere((i) => i.product.id == productId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 18,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            // ref.read() в onPressed — правильно
            ref.read(cartProvider.notifier).decrementQuantity(productId);
          },
        ),
        Text(
          '${item.quantity}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          iconSize: 18,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            ref.read(cartProvider.notifier).incrementQuantity(productId);
          },
        ),
      ],
    );
  }
}
