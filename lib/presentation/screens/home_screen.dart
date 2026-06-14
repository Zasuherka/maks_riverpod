import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maks_riverpod/presentation/providers/search_query_provider.dart';
import 'package:maks_riverpod/presentation/widgets/product_card.dart';
import 'package:maks_riverpod/presentation/providers/cart_provider.dart';
import 'package:maks_riverpod/presentation/providers/products_provider.dart';
import 'package:maks_riverpod/router/app_router.dart';

// =============================================================================
// ДЕМО: ConsumerWidget для главного экрана
// =============================================================================
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() — подписываемся на количество товаров в корзине.
    // Виджет перестроится только когда изменится cartItemCount.
    final itemCount = ref.watch(cartItemCountProvider);
    ref.listen(cartItemCountProvider, (previous, next) {
      if (next > (previous ?? 0)) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Товар добавлен в корзину')));
      } else if (next < (previous ?? 0)) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Товар удалён из корзины')));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        centerTitle: false,
        actions: [
          // Иконка корзины с бейджем
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  // context.push() — добавляет маршрут в стек (можно вернуться)
                  // Аналог Navigator.push(), но декларативный
                  context.push(AppRoutes.cart);
                },
              ),
              if (itemCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: const Column(
        children: [
          _SearchBar(),
          _CategoryFilter(),
          Expanded(child: _ProductGrid()),
        ],
      ),
    );
  }
}

// Строка поиска
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;
  Timer? _searchTimer;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        onChanged: (text) {
          _searchTimer?.cancel();
          _searchTimer = Timer(const Duration(milliseconds: 500), () {
            ref.read(searchQueryProvider.notifier).search(text);
          });
        },
        decoration: InputDecoration(
          hintText: 'Поиск товаров...',
          prefixIcon: const Icon(Icons.search_outlined),
          suffixIcon: const Icon(Icons.clear),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
        ),
      ),
    );
  }
}

// Фильтр категорий
class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() на async провайдер возвращает AsyncValue<T>.
    // Используем when() для обработки трёх состояний.
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox(height: 50),
      error: (err, _) => const SizedBox.shrink(),
      data: (categories) => SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            // Чип "Все"
            _CategoryChip(
              label: 'Все',
              isSelected: selectedCategory == null,
              onTap: () {
                // ref.read() в onTap — правильно
                ref.read(selectedCategoryProvider.notifier).select(null);
              },
            ),
            ...categories.map(
              (category) => _CategoryChip(
                label: category,
                isSelected: selectedCategory == category,
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).select(category);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          labelStyle: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }
}

// Сетка продуктов
class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // filteredProductsProvider — комбинирует два провайдера:
    // productsProvider + selectedCategoryProvider
    final filteredAsync = ref.watch(filteredProductsProvider);

    // AsyncValue.when() — декларативная обработка состояний загрузки
    return filteredAsync.when(
      // Состояние загрузки
      loading: () => const Center(child: CircularProgressIndicator()),

      // Состояние ошибки
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Ошибка: $error'),
            const SizedBox(height: 12),
            FilledButton(
              // ref.invalidate() — принудительно обновить провайдер,
              // заставив его заново выполнить build/fetch
              onPressed: () => ref.invalidate(productsProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),

      // Успешные данные
      data: (products) => products.isEmpty
          ? const Center(child: Text('Товары не найдены'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  ProductCard(product: products[index]),
            ),
    );
  }
}
