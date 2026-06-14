# go_router — Теория и практика (v17.x)

---

## Что такое go_router и зачем он нужен

go_router — официальный пакет навигации от команды Flutter. Декларативная маршрутизация на основе URL.

**Преимущества перед Navigator 2.0:**
- URL-based навигация (работает в web, deeplinks на mobile)
- Декларативное описание всего дерева маршрутов в одном месте
- Встроенная поддержка redirect (гварды)
- Простая вложенная навигация через `StatefulShellRoute`

**Сравнение с auto_route:**
| | go_router | auto_route |
|--|-----------|------------|
| Подход | URL-first | code-gen аннотации |
| Shell route | встроен | `AutoTabsRouter` |
| Redirect | `redirect` callback | Guards (`AutoRouteGuard`) |
| Параметры | path + query | typed параметры |
| Кодогенерация | опционально | обязательна |

---

## Базовая настройка

```dart
// 1. Создаём GoRouter
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/detail/:id',       // :id — параметр пути
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DetailScreen(id: id);
      },
    ),
  ],
);

// 2. Подключаем в MaterialApp
MaterialApp.router(
  routerConfig: router,  // вместо home:
)
```

---

## Типы маршрутов

### GoRoute — базовый маршрут

```dart
GoRoute(
  path: '/products',
  name: 'products',              // именованный маршрут (опционально)
  builder: (context, state) => const ProductsScreen(),

  // Дочерние маршруты — вложены внутри родительского
  routes: [
    GoRoute(
      path: ':id',               // итоговый путь: /products/:id
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailScreen(id: id);
      },
    ),
  ],
)
```

### ShellRoute — общая оболочка без сохранения состояния

Оборачивает группу маршрутов в единый виджет-оболочку (например, с AppBar).
При переключении вкладок состояние **не сохраняется** — виджеты пересоздаются.

```dart
ShellRoute(
  builder: (context, state, child) {
    return Scaffold(
      appBar: AppBar(title: Text(state.uri.path)),
      body: child,  // child — текущий активный дочерний маршрут
    );
  },
  routes: [
    GoRoute(path: '/home', builder: ...),
    GoRoute(path: '/settings', builder: ...),
  ],
)
```

### StatefulShellRoute — вкладки с сохранением состояния ⭐

**Самый важный тип для bottom navigation bar.**
Каждая ветка имеет свой Navigator и сохраняет стек при переключении вкладок.

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    // navigationShell — управление вкладками
    return ScaffoldWithBottomNav(shell: navigationShell);
  },
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(path: '/home', builder: ...),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(path: '/profile', builder: ...),
      ],
    ),
  ],
)
```

```dart
// Виджет оболочки с NavigationBar
class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,  // текущая активная ветка
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          // true = при повторном нажатии на активную вкладку → pop to root
          initialLocation: i == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
```

---

## Навигация (методы)

```dart
// context.go() — ЗАМЕНЯЕТ весь стек (нет кнопки "Назад")
// Используется для: логин → главная, логаут → логин, bottom nav
context.go('/home');
context.goNamed('home');

// context.push() — ДОБАВЛЯЕТ в стек (есть кнопка "Назад")
// Используется для: открыть деталку, открыть корзину
context.push('/cart');
context.pushNamed('cart');

// context.pop() — назад (аналог Navigator.pop())
context.pop();

// context.pushReplacement() — заменяет текущий маршрут в стеке
context.pushReplacement('/new-route');

// context.canPop() — проверить можно ли вернуться
if (context.canPop()) context.pop();
```

### Передача параметров

```dart
// Path parameters — часть URL: /product/42
context.push('/product/42');
// Чтение: state.pathParameters['id']

// Query parameters — после ?: /search?q=молоко&category=dairy
context.push('/search?q=молоко&category=dairy');
// Чтение: state.uri.queryParameters['q']

// Extra — объект в памяти (не сериализуется в URL, теряется при deeplink)
context.push('/cart', extra: cartItem);
// Чтение: state.extra as CartItem
```

---

## Redirect — гварды маршрутов

`redirect` — функция, вызываемая **перед каждым переходом**.
Возвращает `null` (пропустить) или `String` (перенаправить).

### Базовый redirect

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authService.isLoggedIn;
    final isOnLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isOnLogin) return '/login';  // → на логин
    if (isLoggedIn && isOnLogin) return '/home';      // → на главную
    return null;                                       // пропустить
  },
)
```

### Redirect + Riverpod (паттерн этого проекта)

Ключевой паттерн: создаём GoRouter **через Riverpod Provider**, который слушает нужные провайдеры. При их изменении GoRouter пересоздаётся и автоматически вызывает redirect.

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // ref.watch() здесь — при изменении authProvider
  // Riverpod пересоздаст GoRouter → redirect запустится снова
  final authState = ref.watch(authProvider);

  return GoRouter(
    redirect: (context, state) {
      if (!authState.isLoggedIn && state.matchedLocation != '/login') {
        // Сохраняем целевой маршрут в query param
        return '/login?from=${state.matchedLocation}';
      }
      if (authState.isLoggedIn && state.matchedLocation == '/login') {
        return '/home';
      }
      return null;
    },
    routes: [...],
  );
});

// В MaterialApp:
class App extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
    );
  }
}
```

### Redirect с сохранением целевого URL

```dart
// При редиректе на /login сохраняем куда хотел попасть пользователь
redirect: (context, state) {
  if (!isLoggedIn) {
    return '/login?from=${Uri.encodeComponent(state.matchedLocation)}';
  }
  return null;
},

// На экране логина — читаем и используем
GoRoute(
  path: '/login',
  builder: (context, state) {
    final from = state.uri.queryParameters['from'] ?? '/home';
    return LoginScreen(redirectTo: from);
  },
),

// После успешного входа:
ref.read(authProvider.notifier).login(username);
context.go(redirectTo);  // возвращаем пользователя туда куда шёл
```

---

## Вложенная навигация — схема

```
GoRouter
├── StatefulShellRoute (bottom nav bar)
│   ├── Branch 0: Магазин
│   │   └── GoRoute '/'                → HomeScreen
│   │       └── GoRoute 'cart'         → CartScreen      (/cart)
│   │           └── GoRoute 'order/:id'→ OrderScreen     (/cart/order/42)
│   │
│   └── Branch 1: Профиль
│       └── GoRoute '/profile'         → ProfileScreen
│
└── GoRoute '/login'                   → LoginScreen (вне Shell, без bottom nav)
```

**Ключевые моменты:**
- Маршруты ВНЕ `StatefulShellRoute` не показывают bottom nav bar (`/login`)
- Вложенные маршруты (children) работают внутри той же вкладки
- Переход `cart → order` не меняет активную вкладку bottom nav

---

## GoRouterState — информация о текущем маршруте

```dart
GoRoute(
  path: '/product/:id',
  builder: (context, state) {
    state.uri              // Uri текущего маршрута
    state.matchedLocation  // '/product/42'
    state.fullPath         // полный путь включая родителей
    state.pathParameters   // {'id': '42'}
    state.uri.queryParameters  // query params
    state.extra            // объект переданный через extra
    state.name             // имя маршрута если задано

    return ProductScreen(id: state.pathParameters['id']!);
  },
),
```

---

## NavigatorObserver — отладка и аналитика

```dart
class AppRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    // Логирование, аналитика (Firebase Analytics, Amplitude)
    analytics.logScreenView(screenName: route.settings.name);
  }

  @override
  void didPop(Route route, Route? previousRoute) { ... }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) { ... }
}

// Подключение:
GoRouter(
  observers: [AppRouterObserver()],
  routes: [...],
)
```

---

## Кодогенерация (опционально)

go_router поддерживает кодогенерацию через `go_router_builder`. Позволяет типизировать параметры маршрутов.

```dart
// С кодогенерацией (go_router_builder):
@TypedGoRoute<ProductRoute>(path: '/product/:id')
class ProductRoute extends GoRouteData {
  const ProductRoute({required this.id});
  final String id;

  @override
  Widget build(context, state) => ProductScreen(id: id);
}

// Навигация — типизированная:
ProductRoute(id: '42').go(context);
```

В проекте используем **без кодогенерации** — достаточно для понимания концепций.

---

## Именованные маршруты

```dart
GoRoute(
  path: '/cart',
  name: 'cart',  // задаём имя
  builder: ...
)

// Навигация по имени — устойчива к изменению пути
context.goNamed('cart');
context.pushNamed('order', pathParameters: {'orderId': '42'});
context.pushNamed(
  'search',
  queryParameters: {'q': 'молоко'},
);
```

---

## Типичные ошибки и решения

| Ошибка | Причина | Решение |
|--------|---------|---------|
| Нет кнопки "Назад" | Использовал `context.go()` вместо `push()` | Используй `push()` для добавления в стек |
| Bottom nav сбрасывает стек | `ShellRoute` вместо `StatefulShellRoute` | Замени на `StatefulShellRoute.indexedStack` |
| Redirect не срабатывает при изменении состояния | GoRouter создан не через Riverpod Provider | Оберни в `Provider<GoRouter>` с `ref.watch()` |
| Deeplink не работает | Параметры передаются через `extra` | Используй `pathParameters` или `queryParameters` |
| Вложенный маршрут не открывается внутри вкладки | Путь задан абсолютным | Используй относительный путь в `routes:` дочернего |

---

## Структура файлов (этот проект)

```
lib/
  router/
    app_router.dart     # GoRouter + routerProvider + AppRoutes constants
  screens/
    shell_screen.dart   # BottomNavigationBar оболочка для StatefulShellRoute
    login_screen.dart   # вне Shell (нет bottom nav)
    home_screen.dart    # ветка 0
    cart_screen.dart    # вложен в home (/cart)
    order_screen.dart   # вложен в cart (/cart/order/:id)
    profile_screen.dart # ветка 1
  providers/
    auth_provider.dart  # AuthState — источник для redirect-гварда
```

---

## Версия (этот проект)

| Пакет | Версия |
|-------|--------|
| go_router | 17.2.3 |
| Flutter SDK | 3.38.9 |
