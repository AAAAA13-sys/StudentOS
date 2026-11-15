import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the JWT in the platform keystore-backed secure storage.
///
/// The token must never be written anywhere else (no SharedPreferences, no
/// Drift cache, no logs).
class TokenStorage {
  const TokenStorage(this._storage);

  static const String _tokenKey = 'studentos.jwt';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}

final Provider<TokenStorage> tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(FlutterSecureStorage()),
);
