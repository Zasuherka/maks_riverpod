// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoriteRepository)
final favoriteRepositoryProvider = FavoriteRepositoryProvider._();

final class FavoriteRepositoryProvider
    extends
        $FunctionalProvider<
          FavoriteRepository,
          FavoriteRepository,
          FavoriteRepository
        >
    with $Provider<FavoriteRepository> {
  FavoriteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoriteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoriteRepository create(Ref ref) {
    return favoriteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteRepository>(value),
    );
  }
}

String _$favoriteRepositoryHash() =>
    r'7feac31e5f96903996791d7dca1a80de57c1ab13';
