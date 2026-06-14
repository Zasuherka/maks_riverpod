// =============================================================================
// UNIT ТЕСТЫ С МОКАМИ — mockito + кодогенерация
// =============================================================================
// Что такое мок: поддельный объект, который имитирует настоящий.
// Зачем: реальный репозиторий ходит в сеть → тест медленный и нестабильный.
// Мок: возвращает заранее заданные данные → тест быстрый и предсказуемый.
//
// КАК ЗАПУСТИТЬ:
//   1. flutter pub get
//   2. flutter pub run build_runner build
//      → появится products_mock_test.mocks.dart (не трогать руками)
//   3. flutter test test/unit/products_mock_test.dart
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
// annotations.dart — содержит аннотацию @GenerateMocks
import 'package:mockito/annotations.dart';
// mockito.dart — содержит when(), verify(), verifyNever(), any() и прочие утилиты
import 'package:mockito/mockito.dart';
import 'package:maks_riverpod/domain/models/product.dart';

// Импортируем СГЕНЕРИРОВАННЫЙ файл с моками.
// Этот файл создаётся командой: flutter pub run build_runner build
// Он НЕ существует до первого запуска build_runner — это нормально.
import 'products_mock_test.mocks.dart';

// =============================================================================
// ЧАСТЬ 1: Код, который мы будем тестировать
// =============================================================================
// В реальном проекте этот код жил бы в lib/.
// Здесь для наглядности — всё в одном файле.

// Абстрактный класс = интерфейс репозитория.
// "Абстрактный" значит: нет реализации, только контракт (список методов).
// В реальном приложении здесь был бы HTTP-клиент или Hive/SQLite.
abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<Product?> findById(String id);
}

// Сервис — содержит бизнес-логику, зависит от репозитория.
// Принимает ProductRepository через конструктор (Dependency Injection).
// Именно поэтому мы можем подменить настоящий репозиторий моком в тестах.
class ProductService {
  const ProductService(this._repository);

  final ProductRepository _repository;

  // Количество товаров в заданной категории
  Future<int> countInCategory(String category) async {
    final products = await _repository.fetchProducts();
    return products.where((p) => p.category == category).length;
  }

  // Список уникальных категорий
  Future<List<String>> getCategories() async {
    final products = await _repository.fetchProducts();
    return products.map((p) => p.category).toSet().toList();
  }

  // Считается ли товар дорогим (цена > 200 ₽)
  Future<bool> isExpensive(String productId) async {
    final product = await _repository.findById(productId);
    if (product == null) return false;
    return product.price > 200;
  }

  // Самый дорогой товар
  Future<Product?> getMostExpensive() async {
    final products = await _repository.fetchProducts();
    if (products.isEmpty) return null;
    return products.reduce((a, b) => a.price > b.price ? a : b);
  }
}

// =============================================================================
// ЧАСТЬ 2: Аннотация для кодогенерации
// =============================================================================
// @GenerateMocks([ProductRepository]) — инструкция для build_runner:
// "Сгенерируй класс MockProductRepository в файле products_mock_test.mocks.dart"
//
// MockProductRepository будет:
// - extends Mock (от mockito)
// - implements ProductRepository (все методы из интерфейса)
//
// Аннотация ставится на void main() или любой top-level элемент.
@GenerateMocks([ProductRepository])
void main() {
  // Тестовые данные
  const milk = Product(
    id: '1',
    name: 'Молоко',
    category: 'Молочное',
    price: 89.90,
    emoji: '🥛',
  );
  const bread = Product(
    id: '2',
    name: 'Хлеб',
    category: 'Выпечка',
    price: 45.00,
    emoji: '🍞',
  );
  const cheese = Product(
    id: '3',
    name: 'Сыр',
    category: 'Молочное',
    price: 320.00,
    emoji: '🧀',
  );

  // Список для удобства
  final allProducts = [milk, bread, cheese];

  // =========================================================================
  // БАЗОВОЕ ИСПОЛЬЗОВАНИЕ МОКА
  // =========================================================================
  group('ProductService — базовые операции', () {
    // MockProductRepository — сгенерированный класс.
    // Он implements ProductRepository, поэтому компилятор доволен.
    // Все его методы по умолчанию возвращают null (или бросают исключение).
    // Поведение задаётся через when(...).
    late MockProductRepository mockRepo;
    late ProductService service;

    setUp(() {
      // Создаём мок и сервис перед каждым тестом
      mockRepo = MockProductRepository();
      // Передаём МОК вместо настоящего репозитория
      service = ProductService(mockRepo);
    });

    test('countInCategory возвращает правильное количество', () async {
      // when(mock.method()).thenAnswer((_) async => result)
      // "Когда вызовут fetchProducts(), верни этот список (асинхронно)"
      // thenAnswer используется для async-методов (возвращают Future)
      // Параметр (_) — Invocation (можно получить аргументы вызова, нам не нужно)
      when(mockRepo.fetchProducts()).thenAnswer((_) async => allProducts);

      final count = await service.countInCategory('Молочное');

      // Молоко + Сыр = 2 товара в категории 'Молочное'
      expect(count, equals(2));
    });

    test('countInCategory возвращает 0 для несуществующей категории', () async {
      when(mockRepo.fetchProducts()).thenAnswer((_) async => allProducts);

      final count = await service.countInCategory('Морепродукты');

      expect(count, equals(0));
    });

    test('getCategories возвращает список уникальных категорий', () async {
      when(mockRepo.fetchProducts()).thenAnswer((_) async => allProducts);

      final categories = await service.getCategories();

      // 3 товара, но только 2 уникальные категории (Молочное встречается дважды)
      expect(categories, hasLength(2));
      // containsAll — список содержит все перечисленные элементы (порядок не важен)
      expect(categories, containsAll(['Молочное', 'Выпечка']));
    });

    test('isExpensive возвращает true для дорогого товара', () async {
      // thenReturn — для синхронных методов или когда хотим вернуть Future явно.
      // Но для async лучше thenAnswer.
      when(mockRepo.findById('3')).thenAnswer((_) async => cheese);

      final result = await service.isExpensive('3');

      // Сыр стоит 320 ₽ > 200 ₽ → expensive
      expect(result, isTrue);
    });

    test('isExpensive возвращает false для дешёвого товара', () async {
      when(mockRepo.findById('1')).thenAnswer((_) async => milk);

      final result = await service.isExpensive('1');

      // Молоко стоит 89.90 ₽ < 200 ₽ → not expensive
      expect(result, isFalse);
    });

    test('isExpensive возвращает false если товар не найден', () async {
      // Мок возвращает null — товар не существует
      when(mockRepo.findById('999')).thenAnswer((_) async => null);

      final result = await service.isExpensive('999');

      expect(result, isFalse);
    });

    test('getMostExpensive возвращает самый дорогой товар', () async {
      when(mockRepo.fetchProducts()).thenAnswer((_) async => allProducts);

      final product = await service.getMostExpensive();

      // Сыр (320 ₽) дороже всех
      expect(product, equals(cheese));
    });

    test('getMostExpensive возвращает null для пустого списка', () async {
      // Мок возвращает пустой список
      when(mockRepo.fetchProducts()).thenAnswer((_) async => []);

      final product = await service.getMostExpensive();

      // isNull — matcher для значения null
      expect(product, isNull);
    });
  });

  // =========================================================================
  // ВЕРИФИКАЦИЯ — проверяем КАК мок был вызван
  // =========================================================================
  group('ProductService — верификация вызовов', () {
    late MockProductRepository mockRepo;
    late ProductService service;

    setUp(() {
      mockRepo = MockProductRepository();
      service = ProductService(mockRepo);
    });

    test('fetchProducts вызван ровно 1 раз', () async {
      when(mockRepo.fetchProducts()).thenAnswer((_) async => [milk]);

      await service.countInCategory('Молочное');

      // verify(mock.method()) — подтверждаем что метод был вызван.
      // .called(n) — проверяем количество вызовов.
      verify(mockRepo.fetchProducts()).called(1);
    });

    test('findById вызван с правильным id', () async {
      when(mockRepo.findById('1')).thenAnswer((_) async => milk);

      await service.isExpensive('1');

      // Проверяем что findById был вызван именно с аргументом '1'
      verify(mockRepo.findById('1')).called(1);
    });

    test('findById не вызывается при countInCategory', () async {
      when(mockRepo.fetchProducts()).thenAnswer((_) async => [milk]);

      await service.countInCategory('Молочное');

      // verifyNever — метод НЕ должен был вызываться.
      // countInCategory использует fetchProducts, а не findById.
      verifyNever(mockRepo.findById(any));
    });
  });

  // =========================================================================
  // СЦЕНАРИЙ "ОШИБКА" — мок бросает исключение
  // =========================================================================
  group('ProductService — обработка ошибок', () {
    late MockProductRepository mockRepo;
    late ProductService service;

    setUp(() {
      mockRepo = MockProductRepository();
      service = ProductService(mockRepo);
    });

    test('countInCategory пробрасывает ошибку от репозитория', () async {
      // thenThrow — мок бросает исключение при вызове метода.
      // Так мы тестируем поведение сервиса в случае ошибки сети/базы данных.
      when(mockRepo.fetchProducts()).thenThrow(Exception('Network error'));

      // throwsA(isA<Exception>()) — expect для Future, который должен завершиться ошибкой.
      // isA<Exception>() — проверяем тип исключения.
      expect(
        () => service.countInCategory('Молочное'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // =========================================================================
  // any() — матчер для любого аргумента
  // =========================================================================
  group('Использование any() матчера', () {
    late MockProductRepository mockRepo;
    late ProductService service;

    setUp(() {
      mockRepo = MockProductRepository();
      service = ProductService(mockRepo);
    });

    test('any() в when — отвечать на любой id', () async {
      // any — специальный матчер из mockito.
      // "Для ЛЮБОГО аргумента findById() вернуть cheese"
      // Полезно когда не важно какой именно id передадут.
      when(mockRepo.findById(any)).thenAnswer((_) async => cheese);

      // Вызываем с разными id — мок вернёт cheese в обоих случаях
      final result1 = await service.isExpensive('1');
      final result2 = await service.isExpensive('999');

      // Сыр дороже 200 ₽ → оба результата true
      expect(result1, isTrue);
      expect(result2, isTrue);
    });
  });
}
