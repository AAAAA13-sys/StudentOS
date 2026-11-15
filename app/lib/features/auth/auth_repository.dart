import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'user.dart';

/// A user together with the JWT issued for them.
class AuthSession {
  const AuthSession({required this.user, required this.token});

  final User user;
  final String token;
}

/// Calls the Auth Service through the gateway (`/api/auth/*`).
class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final Object? json = await _api.post(
      '/api/auth/register',
      body: <String, String>{
        'name': name,
        'email': email,
        'password': password,
      },
      authenticated: false,
    );
    return _parseSession(json);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final Object? json = await _api.post(
      '/api/auth/login',
      body: <String, String>{'email': email, 'password': password},
      authenticated: false,
    );
    return _parseSession(json);
  }

  Future<User> me() async {
    final Object? json = await _api.get('/api/auth/me');
    if (json is Map<String, dynamic> && json['user'] is Map<String, dynamic>) {
      return User.fromJson(json['user'] as Map<String, dynamic>);
    }
    throw const UnexpectedApiException();
  }

  Future<void> logout() async {
    await _api.post('/api/auth/logout');
  }

  AuthSession _parseSession(Object? json) {
    if (json is Map<String, dynamic> &&
        json['user'] is Map<String, dynamic> &&
        json['token'] is String) {
      return AuthSession(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
      );
    }
    throw const UnexpectedApiException();
  }
}

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (ref) => AuthRepository(ref.watch(apiClientProvider)),
    );
