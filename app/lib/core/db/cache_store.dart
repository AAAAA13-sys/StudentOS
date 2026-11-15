import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../api/api_exception.dart';
import 'app_database.dart';

/// A cached JSON value and when it was saved.
class CacheHit {
  const CacheHit(this.json, this.savedAt);

  /// The decoded JSON (`Map`, `List`, or a primitive).
  final Object? json;

  final DateTime savedAt;
}

/// Key/value JSON cache backed by the Drift `cache_entries` table.
///
/// Every key is prefixed with [namespace], so two accounts on the same phone
/// can never read each other's entries.
class CacheStore {
  const CacheStore(this._database, {required this.namespace});

  final AppDatabase _database;
  final String namespace;

  String _scoped(String key) => '$namespace:$key';

  /// Saves [json] (anything `jsonEncode` accepts) under [key].
  Future<void> put(String key, Object? json) {
    return _database
        .into(_database.cacheEntries)
        .insertOnConflictUpdate(
          CacheEntriesCompanion.insert(
            key: _scoped(key),
            payload: jsonEncode(json),
            savedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ),
        );
  }

  /// Returns the entry saved under [key], or null when there is none.
  Future<CacheHit?> get(String key) async {
    final CacheEntry? entry =
        await (_database.select(_database.cacheEntries)
              ..where((table) => table.key.equals(_scoped(key))))
            .getSingleOrNull();
    if (entry == null) {
      return null;
    }
    return CacheHit(
      jsonDecode(entry.payload),
      DateTime.fromMillisecondsSinceEpoch(entry.savedAt, isUtc: true),
    );
  }

  Future<void> remove(String key) {
    return (_database.delete(
      _database.cacheEntries,
    )..where((table) => table.key.equals(_scoped(key)))).go();
  }

  /// Wipes the whole cache table, for every namespace. Called on logout.
  Future<void> clearAll() => _database.delete(_database.cacheEntries).go();
}

/// Cache for session data that must be readable before the user is known.
final Provider<CacheStore> sessionCacheStoreProvider = Provider<CacheStore>(
  (ref) => CacheStore(ref.watch(appDatabaseProvider), namespace: 'session'),
);

/// The cache feature repositories use. It is namespaced by the signed-in
/// user's id and is rebuilt whenever the account changes. While nobody is
/// signed in it points at a separate `signed-out` namespace, so a screen that
/// is still closing during logout can never touch another account's entries.
final Provider<CacheStore> cacheStoreProvider = Provider<CacheStore>((ref) {
  final int? userId = ref.watch(
    authControllerProvider.select(
      (AuthState state) => state is Authenticated ? state.user.id : null,
    ),
  );
  return CacheStore(
    ref.watch(appDatabaseProvider),
    namespace: userId == null ? 'signed-out' : 'user:$userId',
  );
});

/// The result of [fetchWithCache].
class Cached<T> {
  const Cached(this.data, {this.isOffline = false, this.savedAt});

  final T data;

  /// True when [data] came from the cache because the network call failed.
  /// Screens show the shared `OfflineBanner` in that case.
  final bool isOffline;

  /// When the cached copy was saved; null for fresh network data.
  final DateTime? savedAt;
}

/// The standard read path for feature repositories:
/// network → save JSON → on a connectivity/server failure return the cached
/// JSON flagged as offline. Other failures (401, 404, 422) are rethrown.
Future<Cached<T>> fetchWithCache<T>({
  required CacheStore cache,
  required String key,
  required Future<Object?> Function() fetch,
  required T Function(Object? json) parse,
}) async {
  try {
    final Object? json = await fetch();
    final T data = parse(json);
    await cache.put(key, json);
    return Cached<T>(data);
  } on ApiException catch (error) {
    if (!error.allowsCacheFallback) {
      rethrow;
    }
    final CacheHit? hit = await cache.get(key);
    if (hit == null) {
      rethrow;
    }
    return Cached<T>(parse(hit.json), isOffline: true, savedAt: hit.savedAt);
  }
}
