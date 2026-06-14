import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maks_riverpod/presentation/providers/auth_provider.dart';
import 'package:maks_riverpod/presentation/screens/cart_screen.dart';
import 'package:maks_riverpod/presentation/screens/home_screen.dart';
import 'package:maks_riverpod/presentation/screens/login_screen.dart';
import 'package:maks_riverpod/presentation/screens/order_screen.dart';
import 'package:maks_riverpod/presentation/screens/profile_screen.dart';
import 'package:maks_riverpod/presentation/screens/shell_screen.dart';

// =============================================================================
// ИМЕНОВАННЫЕ ПУТИ — единое место для всех строк маршрутов
// =============================================================================
// Хорошая практика: не писать '/home', '/cart' строками по всему коду.
// Если путь изменится — правишь только здесь.
abstract class AppRoutes {
  static const home = '/';
  static const cart = '/cart';
  static const order = '/cart/order'; // вложенный в cart
  static const profile = '/profile';
  static const login = '/login';
}

// =============================================================================
// ROUTER PROVIDER — интеграция GoRouter с Riverpod
// =============================================================================
// GoRouter создаётся через провайдер, чтобы иметь доступ к другим провайдерам
// внутри redirect-гварда. Это стандартный паттерн go_router + riverpod.
//
// ref.watch(authProvider) внутри провайдера роутера означает:
// когда authProvider изменится (логин/логаут) → роутер пересоздастся
// и автоматически вызовет redirect для всех активных маршрутов.
final routerProvider = Provider<GoRouter>((ref) {
  // Слушаем состояние авторизации.
  // При изменении Riverpod пересоздаст GoRouter и вызовет redirect.
  final authState = ref.watch(authProvider);

  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = authState.isLoggedIn;
    final isOnLoginPage = state.matchedLocation == AppRoutes.login;

    // Если не авторизован и пытается попасть НЕ на /login → редирект на /login
    if (!isLoggedIn && !isOnLoginPage) {
      // Сохраняем куда хотел попасть через extra параметр или queryParam
      return '${AppRoutes.login}?from=${state.matchedLocation}';
    }

    // Если уже авторизован и зашёл на /login → редирект на главную
    if (isLoggedIn && isOnLoginPage) {
      return AppRoutes.home;
    }

    // null = переход разрешён без изменений
    return null;
  }

  return GoRouter(
    // Начальный маршрут при запуске приложения
    initialLocation: AppRoutes.home,

    // =========================================================================
    // REDIRECT — ГВАРД НА ОСНОВЕ RIVERPOD ПРОВАЙДЕРА
    // =========================================================================
    // redirect вызывается ПЕРЕД каждым переходом на любой маршрут.
    // Возвращает:
    //   - null          → пропустить, переход разрешён
    //   - String path   → перенаправить на этот путь вместо целевого
    redirect: redirect,

    // Логирование переходов (удобно при разработке)
    observers: [_AppRouterObserver()],

    routes: [
      // =========================================================================
      // STATEFUL SHELL ROUTE — ВЛОЖЕННАЯ НАВИГАЦИЯ С BOTTOM NAV BAR
      // =========================================================================
      // StatefulShellRoute сохраняет состояние каждой вкладки при переключении.
      // Каждая ветка (branch) — отдельный Navigator со своим стеком.
      //
      // Без StatefulShellRoute при переключении вкладок состояние сбрасывается.
      // С ним — каждая вкладка "запоминает" где ты был внутри неё.
      StatefulShellRoute.indexedStack(
        // builder отвечает за отрисовку "оболочки" с BottomNavigationBar.
        // navigationShell — объект для управления активной вкладкой.
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // ===================================================================
          // ВЕТКА 1: Магазин — вкладка с ВЛОЖЕННЫМИ маршрутами
          // ===================================================================
          // У этой ветки есть дочерние маршруты. Навигация внутри ветки
          // (home → cart → order) происходит внутри её Navigator,
          // не затрагивая другие вкладки.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),

                // Дочерние маршруты — вложены ВНУТРИ этой ветки
                routes: [
                  GoRoute(
                    path: 'cart', // итоговый путь: /cart
                    name: 'cart',
                    builder: (context, state) => const CartScreen(),
                    routes: [
                      // Маршрут оформления заказа — вложен внутри /cart
                      // Это демонстрация вложенности: /cart/order/:id
                      GoRoute(
                        path: 'order/:orderId', // :orderId — параметр пути
                        name: 'order',
                        builder: (context, state) {
                          // Извлекаем параметр из пути
                          final orderId =
                              state.pathParameters['orderId'] ?? '';
                          return OrderScreen(orderId: orderId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ===================================================================
          // ВЕТКА 2: Профиль — простая вкладка без вложенности
          // ===================================================================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // =========================================================================
      // МАРШРУТ ВНЕ SHELL — не показывает BottomNavigationBar
      // =========================================================================
      // /login — полноэкранный маршрут, Shell не применяется.
      // Это стандартный способ делать авторизационные экраны в go_router.
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) {
          // Читаем query-параметр 'from' (куда перенаправить после логина)
          final from = state.uri.queryParameters['from'] ?? AppRoutes.home;
          return LoginScreen(redirectTo: from);
        },
      ),
    ],
  );
});

// =============================================================================
// ROUTER OBSERVER — отладочное логирование переходов
// =============================================================================
// NavigatorObserver позволяет перехватывать push/pop/replace события.
// Полезен для аналитики, логирования, Sentry breadcrumbs.
class _AppRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('[Router] push: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint('[Router] pop: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    debugPrint('[Router] replace: ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }
}
