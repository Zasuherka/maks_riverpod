import 'package:maks_riverpod/domain/repositories/favorite_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_repository_impl.g.dart';

final class FavoriteRepositoryImpl implements FavoriteRepository{
  const FavoriteRepositoryImpl();

  @override
  Future<List<String>> getFavoritesProduct() async{
    await Future.delayed(Duration(seconds: 1));
    return ['1' , '2'];
  }

  @override
  Future<void> addToFavorite(String id) async{
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Future<void> removeToFavorite(String id) async{
    await Future.delayed(Duration(seconds: 1));
  }
}

@riverpod
FavoriteRepository favoriteRepository(Ref ref) {
  // Если бы был datasource — брали бы его через ref.watch:
  // final datasource = ref.watch(exampleDatasourceProvider);
  // return ExampleRepositoryImpl(datasource: datasource);

  return FavoriteRepositoryImpl();
}