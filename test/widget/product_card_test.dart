// =============================================================================
// WIDGET ТЕСТЫ — ProductCard
// =============================================================================
// Widget тест запускает виджет в фейковом Flutter-окружении.
// Ты можешь: найти виджеты, нажимать кнопки, вводить текст, проверять UI.
//
// Чем отличается от unit-теста:
//   unit-тест — чистый Dart, нет Flutter
//   widget-тест — есть Flutter, нет реального устройства
//
// Для виджетов с Riverpod нужно оборачивать в ProviderScope,
// иначе будет ошибка "No ProviderScope found".
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maks_riverpod/domain/models/cart_item.dart';
import 'package:maks_riverpod/domain/models/product.dart';
import 'package:maks_riverpod/presentation/providers/cart_provider.dart';
import 'package:maks_riverpod/widgets/product_card.dart';

// Тестовый продукт — используется во всех тестах
const _testProduct = Product(
  id: '1',
  name: 'Молоко',
  category: 'Молочное',
  price: 89.90,
  emoji: '🥛',
);

// =============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ И КЛАССЫ
// =============================================================================

// buildTestApp() — хелпер для рендеринга ProductCard с ПУСТОЙ корзиной.
// Оборачиваем в:
//   - ProviderScope: нужен для Riverpod (как ProviderScope в main.dart)
//   - MaterialApp: нужен для Theme, Navigator и т.д.
//   - Scaffold: нужен для корректного рендера Material-виджетов
Widget buildTestApp() {
  return const ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          // Задаём размер карточки — иначе она может быть unconstrained
          child: SizedBox(
            width: 200,
            height: 320,
            child: ProductCard(product: _testProduct),
          ),
        ),
      ),
    ),
  );
}

// buildTestAppWithCart() — хелпер для рендеринга ProductCard с ЗАДАННЫМ состоянием корзины.
// cartFactory — функция-фабрика, возвращает экземпляр Cart.
// Riverpod вызовет эту функцию вместо стандартного Cart() при создании провайдера.
//
// Пример использования:
//   buildTestAppWithCart(() => _CartWithProduct())
Widget buildTestAppWithCart(Cart Function() cartFactory) {
  return ProviderScope(
    overrides: [
      // overrideWith() говорит Riverpod:
      // "вместо обычного Cart() используй cartFactory() при создании cartProvider"
      cartProvider.overrideWith(cartFactory),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 320,
            child: ProductCard(product: _testProduct),
          ),
        ),
      ),
    ),
  );
}

// _CartWithProduct — специальный Cart для теста "товар уже в корзине".
// Переопределяем build() чтобы корзина стартовала с 2 единицами тестового товара.
// Это чище мока: не нужен mockito, просто подкласс с другим начальным состоянием.
class _CartWithProduct extends Cart {
  @override
  List<CartItem> build() => [
        CartItem(product: _testProduct, quantity: 2),
      ];
}

// Cart с quantity = 1 — нужен для теста "уменьшение до нуля удаляет товар"
class _CartWithQuantityOne extends Cart {
  @override
  List<CartItem> build() => [
        CartItem(product: _testProduct, quantity: 1),
      ];
}

// =============================================================================
// ТЕСТЫ
// =============================================================================
void main() {
  group('ProductCard', () {
    // =========================================================================
    // testWidgets() — аналог test() для виджетов.
    // Второй параметр — callback с WidgetTester tester.
    // tester — главный инструмент: рендерит виджеты, симулирует действия.
    // Функция ОБЯЗАТЕЛЬНО async, потому что большинство методов tester — await.
    // =========================================================================

    testWidgets('отображает название товара', (WidgetTester tester) async {
      // pumpWidget() — рендерит виджет в фейковое дерево.
      // После этого виджет "нарисован" и можно искать вложенные виджеты.
      await tester.pumpWidget(buildTestApp());

      // find.text('Молоко') — ищет виджет Text с текстом 'Молоко' в дереве.
      // findsOneWidget — matcher: ровно один такой виджет найден.
      expect(find.text('Молоко'), findsOneWidget);
    });

    testWidgets('отображает цену товара', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Цена 89.90 → toStringAsFixed(0) → '90' → отображается как '90 ₽'
      expect(find.text('90 ₽'), findsOneWidget);
    });

    testWidgets('отображает эмодзи товара', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Эмодзи тоже рендерится через виджет Text
      expect(find.text('🥛'), findsOneWidget);
    });

    testWidgets(
      'показывает кнопку "В корзину" когда товара нет в корзине',
      (WidgetTester tester) async {
        // Никаких overrides — корзина пустая по умолчанию
        await tester.pumpWidget(buildTestApp());

        // findsOneWidget — гарантируем что кнопка есть и она одна
        expect(find.text('В корзину'), findsOneWidget);

        // findsNothing — убеждаемся что контролов +/- нет
        expect(find.byIcon(Icons.add_circle_outline), findsNothing);
        expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      },
    );

    testWidgets(
      'нажатие "В корзину" добавляет товар (кнопка исчезает)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp());

        // Убеждаемся что кнопка есть до нажатия
        expect(find.text('В корзину'), findsOneWidget);

        // tap() — симулирует нажатие на виджет
        await tester.tap(find.text('В корзину'));

        // pump() — обрабатывает одно "событие" и перерисовывает дерево.
        // ОБЯЗАТЕЛЬНО вызывать после tap/enterText/любого действия меняющего state!
        // Без pump() виджет не перерисуется и тест увидит старое состояние.
        await tester.pump();

        // После добавления кнопка "В корзину" должна исчезнуть
        expect(find.text('В корзину'), findsNothing);
      },
    );

    testWidgets(
      'нажатие "В корзину" показывает контролы количества',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp());

        await tester.tap(find.text('В корзину'));
        await tester.pump();

        // После добавления должны появиться кнопки +/-
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

        // Количество должно показываться как '1'
        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets(
      'показывает контролы количества когда товар уже в корзине',
      (WidgetTester tester) async {
        // Используем хелпер с кастомным Cart.
        // _CartWithProduct.build() возвращает корзину с 2 молоками.
        // Так мы тестируем состояние "товар уже в корзине" без нажатия кнопок.
        await tester.pumpWidget(buildTestAppWithCart(_CartWithProduct.new));

        // Кнопки управления должны быть видны (товар уже в корзине)
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

        // Количество должно быть '2' (из _CartWithProduct.build())
        expect(find.text('2'), findsOneWidget);

        // Кнопки "В корзину" быть не должно
        expect(find.text('В корзину'), findsNothing);
      },
    );

    testWidgets(
      'кнопка + увеличивает количество',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestAppWithCart(_CartWithProduct.new));

        // Сначала quantity = 2 (из _CartWithProduct)
        expect(find.text('2'), findsOneWidget);

        // Нажимаем кнопку "+"
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pump();

        // Количество должно стать 3
        expect(find.text('3'), findsOneWidget);
      },
    );

    testWidgets(
      'кнопка - уменьшает количество',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestAppWithCart(_CartWithProduct.new));

        // Нажимаем кнопку "-"
        await tester.tap(find.byIcon(Icons.remove_circle_outline));
        await tester.pump();

        // quantity было 2, стало 1
        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets(
      'нажатие - при quantity=1 возвращает кнопку "В корзину"',
      (WidgetTester tester) async {
        // Стартуем с quantity = 1
        await tester.pumpWidget(buildTestAppWithCart(_CartWithQuantityOne.new));

        // Убеждаемся что контролы видны
        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

        // Нажимаем "-" при quantity = 1 → товар должен удалиться из корзины
        await tester.tap(find.byIcon(Icons.remove_circle_outline));
        await tester.pump();

        // После удаления должна снова появиться кнопка "В корзину"
        expect(find.text('В корзину'), findsOneWidget);
        expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      },
    );
  });

  // =========================================================================
  // Пример: использование find.byType() и find.widgetWithText()
  // =========================================================================
  group('ProductCard — поиск виджетов разными способами', () {
    testWidgets('find.byType находит виджет по его типу', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // find.byType(WidgetType) — находит все виджеты заданного типа.
      // Card — тип из Material widgets, используется внутри ProductCard.
      expect(find.byType(Card), findsOneWidget);

      // findsWidgets — находит один ИЛИ БОЛЬШЕ виджетов (хотя бы один).
      // Text виджетов несколько: название, цена, эмодзи.
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('find.widgetWithText находит контейнер с нужным текстом', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // find.widgetWithText(WidgetType, 'text') — найти виджет типа X,
      // который СОДЕРЖИТ внутри себя Text с заданной строкой.
      // Полезно когда один и тот же тип виджета встречается несколько раз.
      expect(
        find.widgetWithText(FilledButton, 'В корзину'),
        findsOneWidget,
      );
    });
  });
}
