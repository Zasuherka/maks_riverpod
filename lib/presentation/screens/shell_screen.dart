import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// =============================================================================
// SHELL SCREEN — оболочка с BottomNavigationBar для StatefulShellRoute
// =============================================================================
// Этот виджет — "рамка" вокруг вкладок. Он рисует BottomNavigationBar
// и показывает содержимое активной ветки через navigationShell.
//
// navigationShell.currentIndex — текущая активная вкладка.
// navigationShell.goBranch(index) — переключить вкладку.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  // StatefulNavigationShell — предоставляет go_router для управления вкладками.
  // Передаётся из StatefulShellRoute.indexedStack builder-а.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // navigationShell сам отображает содержимое активной ветки
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // =================================================================
          // goBranch — переключение вкладок в StatefulShellRoute
          // =================================================================
          // initialLocation: true → при повторном нажатии на активную вкладку
          // переходим к её начальному маршруту (pop to root поведение).
          // Это стандартное UX поведение bottom nav bar.
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Магазин',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
