import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maks_riverpod/presentation/providers/auth_provider.dart';
import 'package:maks_riverpod/router/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    print('object');

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 16),
            Text(
              auth.username ?? 'Гость',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              auth.isLoggedIn ? 'Авторизован' : 'Не авторизован',
              style: TextStyle(
                color: auth.isLoggedIn ? Colors.green : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                // =============================================================
                // context.go() — после логаута гвард redirect сам перенаправит
                // на /login, но явный переход делает UX предсказуемым
                // =============================================================
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
