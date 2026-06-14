import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

// Состояние авторизации пользователя
class AuthState {
  const AuthState({required this.isLoggedIn, this.username});

  final bool isLoggedIn;
  final String? username;

  // Удобные фабричные конструкторы
  const AuthState.guest() : isLoggedIn = false, username = null;
  const AuthState.loggedIn(String name) : isLoggedIn = true, username = name;
}

// =============================================================================
// ДЕМО ДЛЯ GO_ROUTER: провайдер, на который будет смотреть redirect-гвард
// =============================================================================
// keepAlive: true — состояние авторизации должно жить всё время приложения.
// go_router будет слушать этот провайдер и перенаправлять пользователя
// при изменении статуса авторизации.
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState.guest(); // По умолчанию — гость

  void login(String username) {
    state = AuthState.loggedIn(username);
  }

  void logout() {
    state = const AuthState.guest();
  }
}
