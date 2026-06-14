import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maks_riverpod/router/app_router.dart';

void main() {
  runApp(
    // ProviderScope обязателен — создаёт контейнер для всех Riverpod провайдеров
    const ProviderScope(child: ShopApp()),
  );
}

// =============================================================================
// ДЕМО: ConsumerWidget на уровне App — читаем routerProvider
// =============================================================================
// ShopApp теперь ConsumerWidget, потому что нам нужен ref для чтения routerProvider.
// routerProvider — это Riverpod-провайдер, возвращающий GoRouter.
class ShopApp extends ConsumerWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch(routerProvider) — получаем экземпляр GoRouter.
    // При изменении authProvider внутри routerProvider, GoRouter пересоздастся
    // и автоматически вызовет redirect для текущего маршрута.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Riverpod Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      // routerConfig вместо home — передаём GoRouter напрямую
      routerConfig: router,
    );
  }
}
