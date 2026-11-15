import 'package:flutter/foundation.dart';

import 'user.dart';

/// Who is using the app right now.
@immutable
sealed class AuthState {
  const AuthState();
}

/// Startup: the stored token has not been checked yet (splash is shown).
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user, {this.isOffline = false});

  final User user;

  /// True when the session was restored from the cached user because the
  /// server could not be reached at startup.
  final bool isOffline;

  @override
  bool operator ==(Object other) {
    return other is Authenticated &&
        other.user == user &&
        other.isOffline == isOffline;
  }

  @override
  int get hashCode => Object.hash(user, isOffline);
}
