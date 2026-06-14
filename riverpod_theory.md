# Riverpod — Теория и практика (v3.x)

---

## Что такое Riverpod и зачем он нужен

Riverpod — стейт-менеджер для Flutter, созданный автором `provider` как его переработка с нуля.

**Проблемы, которые он решает:**
- `setState` не масштабируется — логика размазывается по виджетам
- `InheritedWidget` / `provider` имеют ограничения: зависят от дерева виджетов, нет compile-time safety
- Riverpod — провайдеры живут независимо от дерева виджетов, полная compile-time безопасность

---

## Ключевые концепции

### 1. ProviderScope

Обязательная обёртка всего приложения. Создаёт `ProviderContainer` — хранилище всех провайдеров.

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

Без `ProviderScope` любое обращение к провайдеру выбросит исключение.

### 2. Провайдер

Провайдер — это **объявление источника состояния**. Не само значение, а инструкция "как его получить".

```dart
// Функция — простой вычисляемый провайдер
@riverpod
String greeting(Ref ref) => 'Привет, мир!';

// Класс — провайдер с мутабельным состоянием
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;          // начальное состояние

  void increment() => state++;
}
```

### 3. Consumer (как читать провайдер в UI)

Есть три варианта виджетов-потребителей:

| Тип | Когда использовать |
|-----|-------------------|
| `ConsumerWidget` | Заменяет `StatelessWidget`, добавляет `WidgetRef ref` в `build()` |
| `ConsumerStatefulWidget` + `ConsumerState` | Нужен и локальный State, и Riverpod |
| `Consumer` (inline) | Нужно локализовать rebuild внутри обычного виджета |

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myProvider);
    return Text('$value');
  }
}
```

---

## ref.watch vs ref.read vs ref.listen

Это **самое важное** — понимать разницу между тремя методами.

### ref.watch — подписка с ребилдом

```dart
// ПРАВИЛЬНО: использовать в build() или в body провайдера
final count = ref.watch(counterProvider);
```

- Подписывается на провайдер
- При изменении значения → виджет / провайдер пересчитывается
- **Только в `build()` виджета или в body провайдера**
- Нельзя использовать в `onPressed`, `initState`, коллбеках

### ref.read — одиночное чтение без подписки

```dart
// ПРАВИЛЬНО: использовать в коллбеках, обработчиках событий
onPressed: () => ref.read(counterProvider.notifier).increment()
```

- Читает текущее значение один раз
- Не создаёт подписку → rebuild не вызывает
- **Только в коллбеках**: `onPressed`, `onTap`, `initState`, `dispose`
- Нельзя использовать в `build()` — изменения не будут отслеживаться

### ref.listen — реакция на изменения без rebuild

```dart
// ПРАВИЛЬНО: вызывать ТОЛЬКО в build()
ref.listen<int>(counterProvider, (previous, next) {
  if (next > 10) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
});
```

- Вызывает коллбек при каждом изменении
- Виджет **не перестраивается** — только side-effect
- Подходит для: показ snackbar, навигация, логирование
- Вызывать **только в `build()`** — не в `initState`, не в коллбеках

### ref.invalidate — принудительное сбрасывание

```dart
// Принудительно пересоздаёт провайдер (как "обновить страницу")
onPressed: () => ref.invalidate(productsProvider)
```

---

## Типы провайдеров (с кодогенерацией)

### Синхронный провайдер (функция)

Простое вычисляемое значение, обычно зависит от других провайдеров.

```dart
@riverpod
double cartTotal(Ref ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.price);
}
// Использование: ref.watch(cartTotalProvider) → double
```

### FutureProvider (async функция)

Для загрузки данных, сетевых запросов.

```dart
@riverpod
Future<List<Product>> products(Ref ref) async {
  await Future.delayed(Duration(seconds: 1)); // имитация сети
  return fetchFromServer();
}
// Использование: ref.watch(productsProvider) → AsyncValue<List<Product>>
```

Виджет получает `AsyncValue<T>` с тремя состояниями:

```dart
final productsAsync = ref.watch(productsProvider);
productsAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Ошибка: $error'),
  data: (products) => ListView(...),
);
```

### StreamProvider (async* функция)

Для работы с потоками данных в реальном времени.

```dart
@riverpod
Stream<OrderStatus> orderStatus(Ref ref, String orderId) async* {
  yield OrderStatus.accepted;
  await Future.delayed(Duration(seconds: 2));
  yield OrderStatus.preparing;
  // ...
}
// Использование: ref.watch(orderStatusProvider('order-1')) → AsyncValue<OrderStatus>
```

### Notifier (класс с мутабельным состоянием)

Основной способ управления сложным состоянием. Заменяет `StateNotifier` из Riverpod 2.x.

```dart
@riverpod
class Cart extends _$Cart {
  @override
  List<CartItem> build() => []; // начальное состояние

  void addItem(CartItem item) {
    state = [...state, item]; // ИММУТАБЕЛЬНОЕ обновление
  }

  void removeItem(String id) {
    state = state.where((i) => i.id != id).toList();
  }
}
// Чтение: ref.watch(cartProvider) → List<CartItem>
// Запись: ref.read(cartProvider.notifier).addItem(item)
```

**Важно:** `state` нельзя мутировать напрямую — нужно присваивать новый объект!

```dart
// НЕПРАВИЛЬНО — Riverpod не увидит изменение
state.add(item);

// ПРАВИЛЬНО — создаём новый список
state = [...state, item];
```

### AsyncNotifier (асинхронный Notifier)

Когда начальное состояние тоже асинхронное.

```dart
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<User> build() async {
    return await fetchCurrentUser(); // загрузка при инициализации
  }

  Future<void> updateName(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => updateUserName(name));
  }
}
```

---

## Family — провайдеры с параметрами

Когда нужен один и тот же провайдер, но для разных данных.

```dart
// С кодогенерацией: просто добавь параметр в функцию/build()
@riverpod
Future<Product> productDetail(Ref ref, String id) async {
  return await fetchProduct(id);
}

// Использование — каждый id создаёт отдельный экземпляр провайдера
ref.watch(productDetailProvider('product-1'))
ref.watch(productDetailProvider('product-2'))
```

Каждый уникальный аргумент — отдельный кешированный экземпляр провайдера.

---

## autoDispose vs keepAlive

### autoDispose (по умолчанию — @riverpod)

```dart
@riverpod  // = @Riverpod(keepAlive: false)
class Filter extends _$Filter {
  @override
  String? build() => null;
}
```

- Провайдер **уничтожается** когда последний слушатель отписывается
- Состояние сбрасывается к начальному при следующем создании
- Подходит для: фильтры, поиск, временные состояния экрана

### keepAlive

```dart
@Riverpod(keepAlive: true)
Future<List<Product>> products(Ref ref) async { ... }
```

- Провайдер **живёт всё время** работы приложения, даже без слушателей
- Данные кешируются между навигациями
- Подходит для: корзина, профиль пользователя, кеш запросов

### ref.keepAlive() — динамическое управление

```dart
@riverpod
Future<String> cachedData(Ref ref) async {
  // Держим провайдер живым первые 5 секунд после отписки
  final link = ref.keepAlive();
  Future.delayed(Duration(seconds: 5), link.close);
  return await fetchData();
}
```

---

## Комбинирование провайдеров

Провайдеры могут зависеть от других через `ref.watch()`.

```dart
// productsProvider — async, загружает все товары
@Riverpod(keepAlive: true)
Future<List<Product>> products(Ref ref) async { ... }

// selectedCategoryProvider — хранит текущий фильтр
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;
}

// filteredProducts — автоматически пересчитывается при изменении ЛЮБОГО из двух
@riverpod
Future<List<Product>> filteredProducts(Ref ref) async {
  final all = await ref.watch(productsProvider.future);
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) return all;
  return all.where((p) => p.category == category).toList();
}
```

Граф зависимостей строится автоматически. Riverpod умно пересчитывает только нужные узлы.

---

## ProviderObserver — отладка и логирование

```dart
class RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? prev, Object? next, ProviderContainer container) {
    print('[${provider.name}] $prev → $next');
  }
}

// Подключение:
ProviderScope(
  observers: [RiverpodLogger()],
  child: MyApp(),
)
```

---

## Overrides — тестирование и DI

```dart
// В тестах — заменяем реальный провайдер на mock
ProviderScope(
  overrides: [
    productsProvider.overrideWith(
      (ref) async => [Product(id: '1', name: 'Test')],
    ),
  ],
  child: MyApp(),
)
```

---

## AsyncValue — работа с асинхронными состояниями

`AsyncValue<T>` — запечатанный класс с тремя вариантами:

```dart
// Полный вариант через when()
asyncValue.when(
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Ошибка'),
  data: (value) => Text('$value'),
);

// Только данные (loading/error игнорируются)
asyncValue.whenData((value) => doSomething(value));

// Безопасное извлечение значения (null при loading/error)
final value = asyncValue.asData?.value;

// Проверки состояния
asyncValue.isLoading     // true когда загружается
asyncValue.hasError      // true при ошибке
asyncValue.hasValue      // true когда есть данные
```

---

## Правила и практики

### Структура файлов

```
lib/
  providers/
    products_provider.dart    # провайдеры + бизнес-логика
    products_provider.g.dart  # генерируется автоматически
    cart_provider.dart
    cart_provider.g.dart
  models/
    product.dart
  screens/
    home_screen.dart
```

### Правила именования (кодогенерация)

| Объявление | Имя провайдера |
|-----------|----------------|
| `@riverpod Future<T> myData(...)` | `myDataProvider` |
| `@riverpod class MyNotifier extends _$MyNotifier` | `myNotifierProvider` |
| `@riverpod T myValue(Ref ref, ArgType arg)` | `myValueProvider(arg)` |

### Ключевые правила

1. **ref.watch() только в build()** — никогда в коллбеках
2. **ref.read() только в коллбеках** — никогда в build()
3. **State — иммутабельный** — всегда создавать новый объект, не мутировать
4. **keepAlive: true** — для данных, которые должны жить всё время приложения
5. **autoDispose (default)** — для временных, экранных состояний
6. **family** — когда один провайдер нужен для разных параметров
7. **Один провайдер — одна ответственность** — не делать провайдеры-монстры

### Антипаттерны (не делай так)

```dart
// НЕПРАВИЛЬНО — ref.watch() в коллбеке
onPressed: () => ref.watch(counterProvider); // ошибка!

// НЕПРАВИЛЬНО — прямая мутация state
state.add(item); // Riverpod не увидит изменение!

// НЕПРАВИЛЬНО — ref.read() в build для отслеживания изменений
Widget build(context, ref) {
  final value = ref.read(provider); // изменения не отследятся!
}

// НЕПРАВИЛЬНО — создавать провайдер внутри виджета
Widget build(context, ref) {
  final myProvider = Provider((ref) => ...); // новый объект каждый rebuild!
}
```

---

## Кодогенерация — команды

```bash
# Однократная генерация
dart run build_runner build

# Генерация с перезаписью конфликтующих файлов
dart run build_runner build --delete-conflicting-outputs

# Отслеживание изменений в реальном времени
dart run build_runner watch
```

После изменения любого файла с `@riverpod` — нужно перезапустить build_runner.

---

## Версии (этот проект)

| Пакет | Версия |
|-------|--------|
| flutter_riverpod | 3.1.0 |
| riverpod_annotation | 4.0.0 |
| riverpod_generator | 4.0.0+1 |
| build_runner | 2.15.0 |
| Flutter SDK | 3.38.9 |
| Dart SDK | 3.10.8 |
