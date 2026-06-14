import 'package:maks_riverpod/domain/models/cart_item.dart';
import 'package:maks_riverpod/domain/models/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_provider.g.dart';

// =============================================================================
// ДЕМО: @Riverpod(keepAlive: true) + Notifier — сложное управление состоянием
// =============================================================================
// Notifier — основной способ управления изменяемым состоянием в Riverpod 3.x.
// Заменяет устаревший StateNotifier.
//
// keepAlive: true — корзина должна жить всё время работы приложения,
// даже когда экран корзины закрыт.
//
// Сгенерированное имя провайдера: cartProvider (первая буква строчная)
@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  // build() — инициализация начального состояния.
  // Вызывается один раз при первом обращении к провайдеру.
  // Возвращаемый тип определяет тип state провайдера.
  @override
  List<CartItem> build() => [];

  // Добавить товар в корзину (или увеличить количество если уже есть)
  void addProduct(Product product) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Riverpod требует ИММУТАБЕЛЬНОГО обновления state.
      // Нельзя менять state напрямую — нужно создавать новый список.
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      // Оператор spread [...] — создаём новый список
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void incrementQuantity(String productId) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: item.quantity + 1)
        else
          item,
    ];
  }

  void decrementQuantity(String productId) {
    final item = state.firstWhere((i) => i.product.id == productId);
    if (item.quantity <= 1) {
      removeProduct(productId);
    } else {
      state = [
        for (final i in state)
          if (i.product.id == productId)
            i.copyWith(quantity: i.quantity - 1)
          else
            i,
      ];
    }
  }

  void clear() => state = [];
}

// =============================================================================
// ДЕМО: Вычисляемые (computed) провайдеры — комбинирование с cartProvider
// =============================================================================
// Простые провайдеры-функции без аннотации класса.
// Автоматически пересчитываются при изменении cartProvider.

// Общая стоимость корзины
@riverpod
double cartTotal(Ref ref) {
  // ref.watch() — подписка. При каждом изменении корзины
  // cartTotalProvider пересчитается и виджеты получат новое значение.
  final cart = ref.watch(cartProvider);
  return cart.fold(
    0.0,
    (sum, item) => sum + item.product.price * item.quantity,
  );
}

// Количество единиц товара в корзине (для бейджа на иконке)
@riverpod
int cartItemCount(Ref ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
}

// Проверка: есть ли конкретный товар в корзине (family провайдер)
// Используется в ProductCard чтобы знать показывать "В корзине" или "Добавить"
@riverpod
bool isProductInCart(Ref ref, String productId) {
  final cart = ref.watch(cartProvider);
  return cart.any((item) => item.product.id == productId);
}
