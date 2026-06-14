import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maks_riverpod/presentation/providers/auth_provider.dart';

// Экран логина — находится ВНЕ ShellRoute, поэтому без BottomNavigationBar
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key, required this.redirectTo});

  // Куда перенаправить после успешного входа (передаётся через query param)
  final String redirectTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 24),
              Text(
                'Войдите в аккаунт',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Гвард go_router перенаправил вас сюда',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () {
                  // Логинимся через Riverpod
                  ref.read(authProvider.notifier).login('Максим');

                  // ==========================================================
                  // context.go() — замена всего стека (не добавляет в историю)
                  // ==========================================================
                  // После логина гвард redirect автоматически сработает,
                  // но явный go() гарантирует мгновенный переход.
                  context.go(redirectTo);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Войти как Максим'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
