import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts how many times a protected call was rejected with 401.
///
/// [ApiClient] bumps it; the auth controller listens and logs the user out.
/// It exists so `core/api` does not depend on `features/auth`.
class UnauthorizedSignal extends Notifier<int> {
  @override
  int build() => 0;

  void notify() => state = state + 1;
}

final NotifierProvider<UnauthorizedSignal, int> unauthorizedSignalProvider =
    NotifierProvider<UnauthorizedSignal, int>(UnauthorizedSignal.new);
