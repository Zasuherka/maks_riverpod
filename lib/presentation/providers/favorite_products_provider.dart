import 'package:maks_riverpod/data/repositories/favorite_repository_impl.dart';
import 'package:maks_riverpod/presentation/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_products_provider.g.dart';

@Riverpod(keepAlive: true)
class FavoriteProducts extends _$FavoriteProducts {
  @override
  Future<List<String>> build() async {
    final repo = ref.watch(favoriteRepositoryProvider);
    ref.watch(authProvider);
    return await repo.getFavoritesProduct();
  }

  void addProduct(String productId) {
    state = AsyncData([...state.value ?? [], productId]);
  }

  void removeProduct(String productId) {
    final current = state.value ?? [];
    state = AsyncData(current.where((id) => id != productId).toList());
  }
}

@riverpod
class IsFavoriteProduct extends _$IsFavoriteProduct {
  @override
  Future<bool> build(String productId) async {
    return await _getValue();
  }

  Future<bool> _getValue() async {
    final products = await ref.read(favoriteProductsProvider.future);
    return products.contains(productId);
  }

  Future<void> editFavorite(String productId) async {
    final isFavorite = state.value ?? false;
    final repo = ref.read(favoriteRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      if (isFavorite) {
        await repo.removeToFavorite(productId);
        ref.read(favoriteProductsProvider.notifier).removeProduct(productId);
      } else {
        await repo.addToFavorite(productId);
        ref.read(favoriteProductsProvider.notifier).addProduct(productId);
      }
      state = AsyncData(!isFavorite);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
