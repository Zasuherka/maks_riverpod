import 'package:maks_riverpod/domain/models/product.dart';
import 'package:maks_riverpod/presentation/providers/search_query_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Директива part указывает, что файл products_provider.g.dart является частью
// этого файла. build_runner генерирует его автоматически из аннотаций @riverpod.
part 'products_provider.g.dart';

// Моковые данные — имитируем ответ сервера
const _mockProducts = [
  Product(
    id: '1',
    name: 'Молоко',
    category: 'Молочное',
    price: 89.90,
    emoji: '🥛',
  ),
  Product(
    id: '2',
    name: 'Кефир',
    category: 'Молочное',
    price: 65.50,
    emoji: '🍶',
  ),
  Product(
    id: '3',
    name: 'Сыр',
    category: 'Молочное',
    price: 320.00,
    emoji: '🧀',
  ),
  Product(
    id: '4',
    name: 'Хлеб',
    category: 'Выпечка',
    price: 45.00,
    emoji: '🍞',
  ),
  Product(
    id: '5',
    name: 'Батон',
    category: 'Выпечка',
    price: 38.00,
    emoji: '🥖',
  ),
  Product(
    id: '6',
    name: 'Яблоки',
    category: 'Фрукты',
    price: 120.00,
    emoji: '🍎',
  ),
  Product(
    id: '7',
    name: 'Бананы',
    category: 'Фрукты',
    price: 95.00,
    emoji: '🍌',
  ),
  Product(
    id: '8',
    name: 'Апельсины',
    category: 'Фрукты',
    price: 145.00,
    emoji: '🍊',
  ),
  Product(
    id: '9',
    name: 'Куриная грудка',
    category: 'Мясо',
    price: 380.00,
    emoji: '🍗',
  ),
  Product(
    id: '10',
    name: 'Говядина',
    category: 'Мясо',
    price: 520.00,
    emoji: '🥩',
  ),
  Product(
    id: '11',
    name: 'Яйца',
    category: 'Прочее',
    price: 110.00,
    emoji: '🥚',
  ),
  Product(
    id: '12',
    name: 'Масло',
    category: 'Прочее',
    price: 195.00,
    emoji: '🧈',
  ),
];

// =============================================================================
// ДЕМО: @Riverpod(keepAlive: true) — FutureProvider (асинхронный провайдер)
// =============================================================================
// keepAlive: true означает, что провайдер НЕ будет уничтожен,
// даже когда ни один виджет его не слушает.
// Используется для данных, которые должны жить всё время работы приложения.
// Без keepAlive провайдер — autoDispose по умолчанию.
//
// Возвращает Future<List<Product>> → при watch() виджет получает
// AsyncValue<List<Product>> (три состояния: loading / data / error)
@Riverpod(keepAlive: true)
Future<List<Product>> products(Ref ref) async {
  // Симулируем задержку сетевого запроса
  await Future.delayed(const Duration(milliseconds: 800));
  return _mockProducts;
}

// =============================================================================
// ДЕМО: @riverpod (autoDispose по умолчанию) + Notifier = StateProvider
// =============================================================================
// @riverpod (строчными) — эквивалент @Riverpod(keepAlive: false).
// Провайдер будет уничтожен, когда последний слушающий его виджет
// покинет дерево виджетов. Состояние сбрасывается при возврате на экран.
//
// Notifier — замена старому StateNotifier.
// Класс обязан реализовать build() — он возвращает начальное состояние.
@riverpod
class SelectedCategory extends _$SelectedCategory {
  // build() вызывается при создании провайдера.
  // null = "Все категории"
  @override
  String? build() => null;

  void select(String? category) => state = category;
}

// =============================================================================
// ДЕМО: Комбинирование провайдеров через ref.watch()
// =============================================================================
// Этот провайдер зависит сразу от двух других:
// 1. productsProvider (async) — полный список товаров
// 2. selectedCategoryProvider — текущий фильтр категории
//
// ref.watch() внутри build/тела провайдера создаёт подписку:
// как только любой из них изменится — filteredProductsProvider пересчитается.
//
// Возвращает Future → тоже становится AsyncValue<List<Product>> у виджета.
@riverpod
Future<List<Product>> filteredProducts(Ref ref) async {
  // .future — "дождись завершения" async-провайдера
  final allProducts = await ref.watch(productsProvider.future);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  late final List<Product> productList;
  if (selectedCategory == null) {
    productList = allProducts;
  } else {
    productList = allProducts
        .where((p) => p.category == selectedCategory)
        .toList();
  }
  if (searchQuery.isEmpty) {
    return productList;
  } else {
    return productList
        .where((product) => product.name.toLowerCase().contains(searchQuery))
        .toList();
  }
}

// =============================================================================
// ДЕМО: Провайдер с параметром (family) — функциональный стиль
// =============================================================================
// Когда функция принимает аргументы помимо Ref — генератор автоматически
// создаёт "family" провайдер. Вызов: ref.watch(productByIdProvider('3'))
// Каждый уникальный аргумент — отдельный экземпляр провайдера.
@riverpod
Product? productById(Ref ref, String id) {
  // ref.watch — подписываемся: если productsProvider обновится,
  // productById тоже пересчитается
  final asyncProducts = ref.watch(productsProvider);

  // asData?.value — безопасно достаём значение только когда данные загружены.
  // Возвращает null пока идёт загрузка или при ошибке.
  final products = asyncProducts.asData?.value;
  if (products == null) return null;
  return products.where((p) => p.id == id).firstOrNull;
}

// Список уникальных категорий (вычисляемый провайдер)
@riverpod
Future<List<String>> productCategories(Ref ref) async {
  final products = await ref.watch(productsProvider.future);
  return products.map((p) => p.category).toSet().toList();
}
