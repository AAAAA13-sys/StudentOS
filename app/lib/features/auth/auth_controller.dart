import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/session_events.dart';
import '../../core/db/cache_store.dart';
import '../../core/storage/token_storage.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'user.dart';

/// Owns the session: restores it at startup, signs in/out, and reacts to a
/// 401 on any protected call by signing the user out.
class AuthController extends Notifier<AuthState> {
  static const String _cachedUserKey = 'user';

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  CacheStore get _sessionCache => ref.read(sessionCacheStoreProvider);

  @override
  AuthState build() {
    ref.listen<int>(unauthorizedSignalProvider, (_, _) {
      unawaited(_endSession());
    });
    unawaited(Future<void>.microtask(_restoreSession));
    return const AuthUnknown();
  }

  /// Throws an [ApiException] (e.g. `UnauthorizedException` for wrong
  /// credentials) so the screen can show it.
  Future<void> login({required String email, required String password}) async {
    final AuthSession session = await _repository.login(
      email: email,
      password: password,
    );
    await _startSession(session);
  }

  /// Throws an [ApiException]; a `ValidationException` carries the field
  /// errors (e.g. "email has already been taken").
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final AuthSession session = await _repository.register(
      name: name,
      email: email,
      password: password,
    );
    await _startSession(session);
  }

  /// Tells the server (best effort), then discards the token and the cache.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } on ApiException {
      // The token is stateless: discarding it locally is what signs out.
    }
    await _endSession();
  }

  Future<void> _restoreSession() async {
    final String? token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      _setState(const Unauthenticated());
      return;
    }
    try {
      final User user = await _repository.me();
      await _sessionCache.put(_cachedUserKey, user.toJson());
      _setState(Authenticated(user));
    } on ApiException catch (error) {
      final User? cachedUser = error.allowsCacheFallback
          ? await _readCachedUser()
          : null;
      if (cachedUser != null) {
        _setState(Authenticated(cachedUser, isOffline: true));
      } else {
        await _endSession();
      }
    }
  }

  Future<User?> _readCachedUser() async {
    final CacheHit? hit = await _sessionCache.get(_cachedUserKey);
    final Object? json = hit?.json;
    return json is Map<String, dynamic> ? User.fromJson(json) : null;
  }

  Future<void> _startSession(AuthSession session) async {
    await _sessionCache.clearAll();
    await _tokenStorage.write(session.token);
    await _sessionCache.put(_cachedUserKey, session.user.toJson());
    _setState(Authenticated(session.user));
  }

  Future<void> _endSession() async {
    _setState(const Unauthenticated());
    await _tokenStorage.clear();
    await _sessionCache.clearAll();
  }

  void _setState(AuthState next) {
    if (ref.mounted) {
      state = next;
    }
  }
}

final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
