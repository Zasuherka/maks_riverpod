# Unit и Widget тесты во Flutter

---

## 1. Что такое тест и зачем он нужен

Тест — это Dart-код, который проверяет что другой код работает правильно.

Например, ты написал `addProduct` в `Cart` — тест проверит:
- после вызова товар появился в корзине
- если добавить тот же товар дважды — quantity становится 2, а не добавляется второй элемент
- total корректно пересчитывается

**Почему тесты важны:**

| Без тестов | С тестами |
|------------|-----------|
| Меняешь код → вручную проверяешь всё в приложении | Меняешь код → запускаешь тесты → они сами всё проверят |
| Регрессии (сломал старое) замечаешь в продакшне | Регрессии ловишь до PR |
| Страшно рефакторить | Рефакторишь смело |
| Поведение кода неочевидно | Тесты = живая документация |

---

## 2. Три уровня тестов во Flutter

```
┌─────────────────────────────────────────────────┐
│           Integration Tests                      │ ← Медленно, тестирует всё
│  (весь app, реальные экраны, реальные данные)    │
├─────────────────────────────────────────────────┤
│           Widget Tests                           │ ← Средне, тестирует UI
│  (один виджет, фейковый Flutter, без устройства) │
├─────────────────────────────────────────────────┤
│           Unit Tests                             │ ← Быстро, тестирует логику
│  (одна функция/класс, чистый Dart, без Flutter)  │
└─────────────────────────────────────────────────┘
```

**Правило:** пиши больше unit-тестов, меньше widget, ещё меньше integration.
Причина — unit-тесты работают за миллисекунды, integration — за секунды.

---

## 3. Unit тесты — тестируем бизнес-логику

Unit тест проверяет одну маленькую единицу (unit) кода **в изоляции**.
"В изоляции" = без Flutter, без базы данных, без сети, без реальных зависимостей.

### Структура unit-теста

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  // group() — группирует связанные тесты под одним названием.
  // В выводе: "Калькулятор > сложение двух чисел"
  group('Калькулятор', () {

    // setUp() — выполняется ПЕРЕД КАЖДЫМ тестом в группе.
    // Здесь создаём объекты, которые нужны каждому тесту.
    late Calculator calc;
    setUp(() {
      calc = Calculator();
    });

    // tearDown() — выполняется ПОСЛЕ КАЖДОГО теста.
    // Здесь освобождаем ресурсы.
    tearDown(() {
      calc.dispose();
    });

    // test() — один тестовый случай.
    // Первый аргумент — описание (что именно тестируем).
    test('сложение двух чисел', () {
      final result = calc.add(2, 3);

      // expect(actual, matcher) — утверждение.
      // actual = что получили, matcher = что ожидали.
      expect(result, equals(5));
    });

  });
}
```

### Тестирование Riverpod провайдеров

Для тестирования провайдеров без Flutter используется `ProviderContainer`:

```dart
// ProviderContainer — изолированное хранилище провайдеров.
// Аналог ProviderScope, но без виджетов. Для чистых unit-тестов.
final container = ProviderContainer();

// Читаем провайдер
final cart = container.read(cartProvider);

// Вызываем методы Notifier
container.read(cartProvider.notifier).addProduct(someProduct);

// Не забывай очищать после теста!
container.dispose();
```

### Важные матчеры (expect-утверждения)

```dart
expect(value, equals(42));          // точное равенство
expect(list, isEmpty);              // пустая коллекция
expect(list, isNotEmpty);           // непустая коллекция
expect(list, hasLength(3));         // длина коллекции
expect(value, isTrue);              // значение true
expect(value, isFalse);             // значение false
expect(value, isNull);              // значение null
expect(value, isNotNull);           // значение не null
expect(value, isA<String>());       // проверка типа
expect(price, closeTo(89.9, 0.01)); // числа с плавающей точкой
expect(list, contains(item));       // коллекция содержит элемент
expect(list, containsAll([a, b]));  // коллекция содержит все элементы
```

---

## 4. Widget тесты — тестируем UI

Widget тест запускает виджет в **фейковом Flutter-окружении** без реального устройства.
Ты можешь симулировать нажатия, скролл, ввод текста и проверять что UI выглядит правильно.

### Структура widget-теста

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  // testWidgets() вместо test() — получаем WidgetTester
  testWidgets('кнопка меняет текст при нажатии', (WidgetTester tester) async {

    // pumpWidget() — рендерит виджет в фейковое дерево
    await tester.pumpWidget(const MyWidget());

    // find.text() — ищет виджет Text с заданной строкой
    expect(find.text('Начало'), findsOneWidget);

    // tap() — симулирует нажатие на найденный виджет
    await tester.tap(find.byType(ElevatedButton));

    // pump() — обрабатывает pending-события и перерисовывает дерево.
    // ОБЯЗАТЕЛЬНО вызывать после любого действия которое меняет state!
    await tester.pump();

    expect(find.text('Нажато!'), findsOneWidget);
  });
}
```

### Основные инструменты WidgetTester

```dart
// Рендеринг
await tester.pumpWidget(widget);       // первый рендер
await tester.pump();                   // перерисовать (обработать 1 кадр)
await tester.pumpAndSettle();          // ждать пока все анимации завершатся

// Действия
await tester.tap(finder);             // нажать
await tester.doubleTap(finder);       // двойной тап
await tester.longPress(finder);       // долгое нажатие
await tester.enterText(finder, 'hi'); // ввести текст
await tester.drag(finder, Offset(0, 100)); // потянуть

// Поиск виджетов (Finder)
find.text('Привет')          // по тексту
find.byType(ElevatedButton)  // по типу виджета
find.byKey(Key('myKey'))     // по ключу
find.byIcon(Icons.add)       // по иконке
find.widgetWithText(Card, 'Молоко') // виджет типа Card с текстом 'Молоко'

// Проверки (Matcher для find)
findsOneWidget    // ровно один виджет
findsNothing      // ни одного виджета
findsWidgets      // один или больше
findsNWidgets(3)  // ровно 3 виджета
```

### Widget тесты с Riverpod

Виджет, который использует Riverpod, нужно обернуть в `ProviderScope`:

```dart
await tester.pumpWidget(
  ProviderScope(
    // overrides — подмена провайдеров для теста
    overrides: [
      cartProvider.overrideWith(() => FakeCart()),
    ],
    child: MaterialApp(
      home: Scaffold(body: ProductCard(product: testProduct)),
    ),
  ),
);
```

`overrideWith()` позволяет подменить провайдер другой реализацией.
Например, подставить корзину с заранее добавленными товарами.

---

## 5. Что такое Mock (мок)

Mock = **поддельный объект**, который притворяется настоящим.

### Зачем нужны моки

Представь, что у тебя есть сервис, который:
- Ходит в сеть за списком продуктов
- Зависит от репозитория (базы данных)

Если тестировать с настоящей реализацией:
- Тест медленный (ждёт сеть / диск)
- Тест нестабильный (нет интернета → тест упал)
- Нельзя проверить сценарий "сервер вернул ошибку"

Мок решает всё это:

```
Настоящий репозиторий: идёт в сеть → непредсказуемо
МОК-репозиторий:       возвращает заранее заданный список → всегда одинаково
```

### Структура с моком

```dart
// Настоящий код (в lib/)
abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
}

class ProductService {
  ProductService(this._repo);
  final ProductRepository _repo;

  Future<int> countProducts() async {
    final products = await _repo.fetchProducts();
    return products.length;
  }
}

// В тесте:
// Вместо настоящего репозитория подставляем мок
final mockRepo = MockProductRepository();

// Настраиваем: "когда вызовут fetchProducts(), верни этот список"
when(mockRepo.fetchProducts()).thenAnswer((_) async => [milk, bread]);

final service = ProductService(mockRepo);
final count = await service.countProducts();

expect(count, equals(2)); // ✅
```

---

## 6. mockito — кодогенерация моков

**mockito** — самая популярная библиотека для моков в Dart.
Моки создаются через кодогенерацию (как `.g.dart` файлы у Riverpod).

### Шаг 1: Добавить в pubspec.yaml

```yaml
dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.15.0  # уже есть в нашем проекте
```

### Шаг 2: Пометить тест аннотацией

```dart
import 'package:mockito/annotations.dart';

// Эта аннотация говорит build_runner: "сгенерируй MockProductRepository"
@GenerateMocks([ProductRepository])
void main() { ... }
```

### Шаг 3: Запустить кодогенерацию

```bash
flutter pub run build_runner build
```

После этого появится файл `my_test.mocks.dart` рядом с тестом.
Он содержит класс `MockProductRepository extends Mock implements ProductRepository`.

### Шаг 4: Импортировать и использовать

```dart
import 'my_test.mocks.dart'; // импортируем сгенерированный файл

final mock = MockProductRepository();
when(mock.fetchProducts()).thenAnswer((_) async => products);
```

### Основные методы mockito

```dart
// Настройка поведения (тренировка мока)
when(mock.someMethod()).thenReturn(value);          // вернуть значение
when(mock.someMethod()).thenAnswer((_) async => x); // для async методов
when(mock.someMethod()).thenThrow(Exception('err')); // бросить исключение

// Проверка вызовов (верификация)
verify(mock.someMethod()).called(1);    // вызван ровно 1 раз
verify(mock.someMethod()).called(3);    // вызван 3 раза
verifyNever(mock.someMethod());         // никогда не вызван

// Матчеры аргументов
when(mock.findById(any)).thenReturn(x); // любой аргумент
when(mock.findById('1')).thenReturn(x); // конкретный аргумент
```

---

## 7. Как запускать тесты

```bash
# Все тесты
flutter test

# Конкретный файл
flutter test test/unit/cart_notifier_test.dart

# Конкретная директория
flutter test test/unit/

# С подробным выводом
flutter test --reporter expanded

# Генерация моков (перед первым запуском тестов с @GenerateMocks)
flutter pub run build_runner build
```

---

## 8. Структура тестовой директории

```
test/
  unit/
    cart_notifier_test.dart        ← unit тесты Cart (без моков)
    products_mock_test.dart        ← unit тесты с моками + пример mockito
    products_mock_test.mocks.dart  ← СГЕНЕРИРОВАНО build_runner (не трогать)
  widget/
    product_card_test.dart         ← widget тесты ProductCard
```

---

## 9. Тестирование BLoC

### Чем BLoC отличается от Riverpod в тестах

В Riverpod ты тестируешь провайдер напрямую через `ProviderContainer.read()`.
В BLoC всё строится вокруг **стрима состояний**: ты добавляешь событие → BLoC
эмиттит одно или несколько состояний → ты проверяешь весь список эмитов по порядку.

Для этого существует специальный пакет `bloc_test`.

```
Riverpod:  container.read(provider)  →  смотришь текущий state
BLoC:      bloc.add(event)           →  слушаешь поток state-ов
```

---

### Зависимости

```yaml
dev_dependencies:
  bloc_test: ^9.1.7    # blocTest(), MockBloc, MockCubit
  mocktail: ^1.0.4     # when(), verify(), whenListen() — без кодогенерации
```

> **Почему `mocktail`, а не `mockito`?**
> `bloc_test` использует `mocktail` внутри. Плюс `mocktail` не требует кодогенерации —
> моки создаются одной строкой без запуска `build_runner`.

---

### Cubit — самый простой случай

`Cubit` не имеет событий, только методы. Тестировать проще всего.

Допустим у нас есть:
```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset()     => emit(0);
}
```

Тесты:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // blocTest — специальная обёртка над test() для BLoC/Cubit.
  // Внутри она: создаёт BLoC → подписывается на стрим → выполняет act →
  // собирает все эмиттнутые состояния → сравнивает с expect.
  blocTest<CounterCubit, int>(
    'increment: [0] → [1]',

    // build — создаёт экземпляр Cubit перед тестом.
    // Вызывается каждый раз, поэтому каждый тест стартует с чистым состоянием.
    build: () => CounterCubit(),

    // act — выполняет действие на Cubit.
    // Здесь вызываем методы (в BLoC — добавляем события через bloc.add()).
    act: (cubit) => cubit.increment(),

    // expect — список состояний, которые должны быть эмиттены в таком порядке.
    // ВАЖНО: сюда входят только состояния ПОСЛЕ подписки, начальное (0) не считается.
    expect: () => [1],
  );

  blocTest<CounterCubit, int>(
    'increment трижды: [1, 2, 3]',
    build: () => CounterCubit(),
    // act может вызывать несколько методов — все состояния попадут в expect
    act: (cubit) {
      cubit.increment();
      cubit.increment();
      cubit.increment();
    },
    expect: () => [1, 2, 3],
  );

  blocTest<CounterCubit, int>(
    'reset возвращает 0',
    build: () => CounterCubit(),
    // seed — переопределяет начальное состояние.
    // Полезно когда нужно тестировать переход из конкретного состояния,
    // не выполняя все предшествующие действия.
    seed: () => 5,
    act: (cubit) => cubit.reset(),
    expect: () => [0],
  );

  blocTest<CounterCubit, int>(
    'decrement ниже нуля — ничего не эмиттится (если бизнес-логика запрещает)',
    build: () => CounterCubit(),
    seed: () => 0,
    act: (cubit) => cubit.decrement(),
    // expect: () => [] — пустой список означает "состояний эмиттиться не должно"
    expect: () => [],
  );
}
```

---

### BLoC с событиями

Когда есть события (`Event`), паттерн тот же, но в `act` используется `bloc.add()`:

```dart
// Events
abstract class CartEvent {}
class AddProductEvent extends CartEvent {
  AddProductEvent(this.product);
  final Product product;
}
class ClearCartEvent extends CartEvent {}

// States
abstract class CartState extends Equatable {}
class CartEmptyState extends CartState {
  @override List<Object> get props => [];
}
class CartLoadingState extends CartState {
  @override List<Object> get props => [];
}
class CartLoadedState extends CartState {
  CartLoadedState({required this.items, required this.total});
  final List<CartItem> items;
  final double total;
  @override List<Object> get props => [items, total];
}
```

Тесты:
```dart
blocTest<CartBloc, CartState>(
  'AddProductEvent → [CartLoadedState]',
  build: () => CartBloc(),
  act: (bloc) => bloc.add(AddProductEvent(milk)),

  // isA<CartLoadedState>() — проверяем тип состояния без жёсткого equals().
  // .having() — проверяем конкретное поле: (объект) => поле, 'имя поля', matcher.
  // Удобно когда State не implements Equatable или нужно проверить только часть полей.
  expect: () => [
    isA<CartLoadedState>()
        .having((s) => s.items, 'items', hasLength(1))
        .having((s) => s.total, 'total', closeTo(89.90, 0.01)),
  ],
);

blocTest<CartBloc, CartState>(
  'ClearCartEvent после добавления → [CartEmptyState]',
  build: () => CartBloc(),
  // seed — стартуем с заполненной корзиной, не добавляя товары через события
  seed: () => CartLoadedState(items: [CartItem(product: milk, quantity: 1)], total: 89.90),
  act: (bloc) => bloc.add(ClearCartEvent()),
  expect: () => [isA<CartEmptyState>()],
);
```

---

### Параметры blocTest — полная шпаргалка

```dart
blocTest<MyBloc, MyState>(
  'описание теста',

  // ОБЯЗАТЕЛЬНЫЕ
  build: () => MyBloc(mockRepo),  // создать BLoC / Cubit
  expect: () => [StateA(), StateB()], // ожидаемые состояния по порядку

  // ЧАСТО НУЖНЫЕ
  seed: () => InitialState(), // начальное состояние вместо дефолтного
  act: (bloc) => bloc.add(SomeEvent()), // что делаем с BLoC

  // ДОПОЛНИТЕЛЬНЫЕ
  // setUp — выполняется ДО build. Здесь настраиваем моки.
  setUp: () {
    when(() => mockRepo.fetch()).thenAnswer((_) async => items);
  },

  // tearDown — выполняется ПОСЛЕ теста. Очистка ресурсов.
  tearDown: () => mockRepo.dispose(),

  // verify — проверки ПОСЛЕ того как все состояния эмиттнуты.
  // Используем для верификации вызовов моков.
  verify: (bloc) {
    verify(() => mockRepo.fetch()).called(1);
  },

  // errors — когда BLoC должен бросить ошибку (addError / throw внутри handler-а)
  errors: () => [isA<NetworkException>()],

  // wait — ждать перед проверкой (нужно для debounce, Timer, Stream-задержек)
  wait: const Duration(milliseconds: 300),
);
```

---

### BLoC с зависимостями — используем моки

Если BLoC зависит от репозитория — мокаем его через `mocktail`:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

// Мок репозитория — одна строка, без кодогенерации.
// MockProductRepository implements ProductRepository автоматически.
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepo;

  setUp(() {
    mockRepo = MockProductRepository();
  });

  blocTest<ProductBloc, ProductState>(
    'LoadProductsEvent → [Loading, Loaded]',
    setUp: () {
      // Настраиваем мок ДО build (setUp выполняется раньше build)
      when(() => mockRepo.fetchProducts())
          .thenAnswer((_) async => [milk, bread]);
    },
    build: () => ProductBloc(mockRepo),
    act: (bloc) => bloc.add(LoadProductsEvent()),
    expect: () => [
      isA<ProductLoadingState>(),
      isA<ProductLoadedState>()
          .having((s) => s.products, 'products', hasLength(2)),
    ],
    verify: (bloc) {
      // Проверяем что репозиторий вызвали ровно 1 раз
      verify(() => mockRepo.fetchProducts()).called(1);
    },
  );

  blocTest<ProductBloc, ProductState>(
    'LoadProductsEvent при ошибке сети → [Loading, Error]',
    setUp: () {
      // Мок бросает исключение — тестируем обработку ошибок
      when(() => mockRepo.fetchProducts())
          .thenThrow(Exception('No internet'));
    },
    build: () => ProductBloc(mockRepo),
    act: (bloc) => bloc.add(LoadProductsEvent()),
    expect: () => [
      isA<ProductLoadingState>(),
      isA<ProductErrorState>(),
    ],
  );
}
```

---

### Widget тесты с BLoC

Для widget-тестов создаём `MockBloc` через `mocktail`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

// MockBloc — специальный класс из пакета bloc_test.
// Extends Mock (mocktail) + Implements CartBloc.
// Позволяет задавать state и стрим событий без реальной логики.
class MockCartBloc extends MockBloc<CartEvent, CartState> implements CartBloc {}

void main() {
  late MockCartBloc mockBloc;

  setUp(() {
    mockBloc = MockCartBloc();
  });

  tearDown(() => mockBloc.close());

  testWidgets('CartScreen показывает товары из состояния BLoC', (tester) async {
    // when(() => mockBloc.state) — задаём текущее состояние мока.
    // Виджет при рендере прочитает этот state через BlocBuilder.
    when(() => mockBloc.state).thenReturn(
      CartLoadedState(items: [CartItem(product: milk, quantity: 2)], total: 179.80),
    );

    // BlocProvider.value — предоставляем УЖЕ СОЗДАННЫЙ BLoC виджету.
    // Используем .value когда BLoC создан снаружи (как наш mock).
    // (Без .value BlocProvider создаёт BLoC сам и управляет его жизнью.)
    await tester.pumpWidget(
      BlocProvider<CartBloc>.value(
        value: mockBloc,
        child: const MaterialApp(home: CartScreen()),
      ),
    );

    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('180 ₽'), findsOneWidget);
  });

  testWidgets('CartScreen реагирует на новый state из стрима', (tester) async {
    // Начальное состояние — корзина пустая
    when(() => mockBloc.state).thenReturn(CartEmptyState());

    // whenListen — настраиваем стрим состояний, которые придут ПОСЛЕ рендера.
    // Первый аргумент: мок-блок.
    // Второй: стрим новых состояний.
    // initialState: что покажет BlocBuilder при первом рендере.
    whenListen(
      mockBloc,
      Stream.fromIterable([
        CartLoadedState(items: [CartItem(product: milk, quantity: 1)], total: 89.90),
      ]),
      initialState: CartEmptyState(),
    );

    await tester.pumpWidget(
      BlocProvider<CartBloc>.value(
        value: mockBloc,
        child: const MaterialApp(home: CartScreen()),
      ),
    );

    // Первый рендер — пустая корзина
    expect(find.text('Корзина пуста'), findsOneWidget);

    // pumpAndSettle — ждём пока стрим доставит новое состояние и виджет перерисуется
    await tester.pumpAndSettle();

    // После получения нового состояния — показывается товар
    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Корзина пуста'), findsNothing);
  });
}
```

---

### Сравнение: BLoC vs Riverpod тестирование

| | BLoC | Riverpod |
|---|---|---|
| **Инструмент** | `bloc_test` + `mocktail` | `ProviderContainer` + `mockito` |
| **Основная функция** | `blocTest()` | `container.read()` |
| **Кодогенерация для моков** | Нет (`mocktail`) | Да (`@GenerateMocks`) |
| **Тест состояния** | проверяешь **список** эмитов | проверяешь **текущее** значение |
| **Widget-тест** | `BlocProvider.value` + `MockBloc` | `ProviderScope(overrides: [...])` |
| **Начальное состояние** | `seed: () => State()` | `overrideWith(() => CustomNotifier())` |
| **Async ожидание** | `wait: Duration(ms: 300)` | `await container.read(provider.future)` |

---

## Файлы с примерами

| Файл | Что показывает |
|------|---------------|
| `test/unit/cart_notifier_test.dart` | ProviderContainer, group/setUp/tearDown, matchers |
| `test/unit/products_mock_test.dart` | @GenerateMocks, when/verify, тестирование через мок |
| `test/widget/product_card_test.dart` | testWidgets, find, pump, overrideWith |
