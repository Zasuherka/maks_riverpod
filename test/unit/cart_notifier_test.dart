// =============================================================================
// UNIT ТЕСТЫ — Cart Notifier
// =============================================================================
// Unit тест = тестирует одну единицу кода в изоляции, без Flutter и без UI.
//
// Что тестируем здесь:
//   - логику Cart (addProduct, removeProduct, increment/decrement, clear)
//   - вычисляемые провайдеры (cartTotal, cartItemCount, isProductInCart)
//
// Инструмент: ProviderContainer — изолированное хранилище провайдеров.
// Это Riverpod-аналог ProviderScope, но без виджетов.
// Каждый тест получает свой чистый контейнер → тесты не влияют друг на друга.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maks_riverpod/domain/models/cart_item.dart';
import 'package:maks_riverpod/domain/models/product.dart';
import 'package:maks_riverpod/presentation/providers/cart_provider.dart';

// Тестовые данные — константы, чтобы не дублировать в каждом тесте
const _milk = Product(
  id: '1',
  name: 'Молоко',
  category: 'Молочное',
  price: 89.90,
  emoji: '🥛',
);

const _bread = Product(
  id: '2',
  name: 'Хлеб',
  category: 'Выпечка',
  price: 45.00,
  emoji: '🍞',
);

const _cheese = Product(
  id: '3',
  name: 'Сыр',
  category: 'Молочное',
  price: 320.00,
  emoji: '🧀',
);

void main() {
  // =========================================================================
  // group() — группирует связанные тесты под одним именем.
  // В выводе консоли: "Cart Notifier > начальное состояние пустое"
  // =========================================================================
  group('Cart Notifier', () {
    // late — объявляем переменную, которая будет проинициализирована в setUp().
    // Не можем создать ProviderContainer на уровне класса — он одноразовый.
    late ProviderContainer container;

    // setUp() — выполняется ПЕРЕД КАЖДЫМ тестом в этой группе.
    // Создаём свежий контейнер для каждого теста.
    // Без этого состояние одного теста "утекает" в следующий.
    setUp(() {
      container = ProviderContainer();
    });

    // tearDown() — выполняется ПОСЛЕ КАЖДОГО теста.
    // dispose() освобождает ресурсы контейнера и все провайдеры внутри.
    tearDown(() {
      container.dispose();
    });

    // -------------------------------------------------------------------------
    // test() — один тестовый случай.
    // Первый аргумент — описание (что именно проверяем).
    // -------------------------------------------------------------------------

    test('начальное состояние — пустой список', () {
      // container.read(provider) — читает текущее значение провайдера.
      // cartProvider — NotifierProvider<Cart, List<CartItem>>
      // Без .notifier читаем state (List<CartItem>), а не сам Notifier.
      final cart = container.read(cartProvider);

      // expect(actual, matcher) — главная конструкция в тестах.
      // actual — то, что получили.
      // matcher — то, чего ожидаем.
      // isEmpty — встроенный matcher: коллекция должна быть пустой.
      expect(cart, isEmpty);
    });

    test('addProduct добавляет товар в корзину', () {
      // .notifier — доступ к самому Notifier (Cart), чтобы вызывать методы.
      // Без .notifier ты получишь state (List<CartItem>), а не Cart.
      container.read(cartProvider.notifier).addProduct(_milk);

      final cart = container.read(cartProvider);

      // hasLength(1) — коллекция должна содержать ровно 1 элемент.
      expect(cart, hasLength(1));

      // cart[0].product == _milk — первый элемент это молоко.
      // equals() — проверяет равенство через ==.
      expect(cart[0].product, equals(_milk));

      // При первом добавлении quantity должен быть 1.
      expect(cart[0].quantity, equals(1));
    });

    test('addProduct увеличивает quantity если товар уже в корзине', () {
      // Добавляем один и тот же товар дважды
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_milk);

      final cart = container.read(cartProvider);

      // Должен быть 1 элемент (не 2), но с quantity = 2
      expect(cart, hasLength(1));
      expect(cart[0].quantity, equals(2));
    });

    test('addProduct добавляет несколько разных товаров', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_bread);

      final cart = container.read(cartProvider);

      // Два разных товара → два разных элемента в корзине
      expect(cart, hasLength(2));
    });

    test('removeProduct удаляет товар из корзины', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_bread);
      container.read(cartProvider.notifier).removeProduct(_milk.id);

      final cart = container.read(cartProvider);

      // Остался только хлеб
      expect(cart, hasLength(1));
      expect(cart[0].product, equals(_bread));
    });

    test('incrementQuantity увеличивает количество товара', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).incrementQuantity(_milk.id);

      final cart = container.read(cartProvider);

      // addProduct дал 1, incrementQuantity добавил ещё 1 → итого 2
      expect(cart[0].quantity, equals(2));
    });

    test('decrementQuantity уменьшает количество товара', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).decrementQuantity(_milk.id);

      final cart = container.read(cartProvider);

      // Было 2, уменьшили на 1 → стало 1
      expect(cart[0].quantity, equals(1));
    });

    test('decrementQuantity удаляет товар когда quantity становится 0', () {
      // Добавляем один раз → quantity = 1
      container.read(cartProvider.notifier).addProduct(_milk);

      // Декрементируем с quantity = 1 → должен удалиться из корзины
      container.read(cartProvider.notifier).decrementQuantity(_milk.id);

      final cart = container.read(cartProvider);

      // Корзина должна быть пустой
      expect(cart, isEmpty);
    });

    test('clear() очищает всю корзину', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_bread);
      container.read(cartProvider.notifier).addProduct(_cheese);

      container.read(cartProvider.notifier).clear();

      expect(container.read(cartProvider), isEmpty);
    });
  });

  // =========================================================================
  // Тесты вычисляемых (computed) провайдеров
  // Эти провайдеры зависят от cartProvider и пересчитываются при его изменении.
  // =========================================================================
  group('Вычисляемые провайдеры корзины', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('cartTotalProvider возвращает 0 для пустой корзины', () {
      final total = container.read(cartTotalProvider);

      // closeTo(expected, delta) — для double: ожидаем 0.0 с точностью ±0.001
      // Никогда не сравнивай double через equals() — из-за погрешности точки.
      expect(total, closeTo(0.0, 0.001));
    });

    test('cartTotalProvider правильно считает сумму одного товара', () {
      container.read(cartProvider.notifier).addProduct(_milk);

      // _milk.price = 89.90, quantity = 1 → итого 89.90
      expect(container.read(cartTotalProvider), closeTo(89.90, 0.001));
    });

    test('cartTotalProvider правильно считает сумму нескольких товаров', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_bread);

      // 89.90 + 45.00 = 134.90
      expect(container.read(cartTotalProvider), closeTo(134.90, 0.001));
    });

    test('cartTotalProvider учитывает quantity', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_milk);

      // 89.90 * 2 = 179.80
      expect(container.read(cartTotalProvider), closeTo(179.80, 0.001));
    });

    test('cartItemCountProvider возвращает 0 для пустой корзины', () {
      expect(container.read(cartItemCountProvider), equals(0));
    });

    test('cartItemCountProvider считает суммарное количество единиц', () {
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_milk);
      container.read(cartProvider.notifier).addProduct(_bread);

      // Молоко x2 + Хлеб x1 = 3 единицы (не 2 позиции!)
      expect(container.read(cartItemCountProvider), equals(3));
    });

    test('isProductInCartProvider возвращает false для пустой корзины', () {
      // isProductInCartProvider — family провайдер, принимает id товара.
      // Передаём id молока, которого нет в корзине.
      final isInCart = container.read(isProductInCartProvider(_milk.id));

      // isFalse — matcher для значения false
      expect(isInCart, isFalse);
    });

    test('isProductInCartProvider возвращает true когда товар добавлен', () {
      container.read(cartProvider.notifier).addProduct(_milk);

      expect(container.read(isProductInCartProvider(_milk.id)), isTrue);
    });

    test('isProductInCartProvider возвращает false для другого товара', () {
      container.read(cartProvider.notifier).addProduct(_milk);

      // Молоко добавлено, но хлеб нет
      expect(container.read(isProductInCartProvider(_bread.id)), isFalse);
    });
  });

  // =========================================================================
  // Пример теста с предварительно настроенным состоянием
  // Иногда нужно протестировать переход из одного состояния в другое.
  // =========================================================================
  group('Последовательность операций (сценарные тесты)', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('полный сценарий: добавить → изменить кол-во → удалить', () {
      final notifier = container.read(cartProvider.notifier);

      // Шаг 1: добавляем два товара
      notifier.addProduct(_milk);
      notifier.addProduct(_bread);
      expect(container.read(cartProvider), hasLength(2));

      // Шаг 2: увеличиваем количество молока
      notifier.incrementQuantity(_milk.id);
      expect(container.read(cartItemCountProvider), equals(3));

      // Шаг 3: удаляем хлеб
      notifier.removeProduct(_bread.id);
      expect(container.read(cartProvider), hasLength(1));

      // Шаг 4: проверяем что молоко осталось с правильным quantity
      final cart = container.read(cartProvider);
      expect(cart[0].product.id, equals(_milk.id));
      expect(cart[0].quantity, equals(2));

      // Шаг 5: очищаем корзину
      notifier.clear();
      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartTotalProvider), closeTo(0.0, 0.001));
    });
  });
}
