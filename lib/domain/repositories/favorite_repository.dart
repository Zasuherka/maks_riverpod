abstract class FavoriteRepository{
  Future<List<String>> getFavoritesProduct();
  Future<void> addToFavorite(String id);
  Future<void> removeToFavorite(String id);
}