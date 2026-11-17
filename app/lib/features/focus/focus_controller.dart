import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alarm.dart';
import 'focus_plan.dart';
import 'focus_platform.dart';
import 'focus_repository.dart';

/// Every alarm. Each change is handed to Android so it rings with the app
/// closed.
class AlarmController extends AsyncNotifier<List<Alarm>> {
  FocusRepository get _repo => ref.read(focusRepositoryProvider);
  FocusPlatform get _platform => ref.read(focusPlatformProvider);

  @override
  FutureOr<List<Alarm>> build() => _load();

  Future<List<Alarm>> _load() async {
    // One-time alarms that rang while the app was closed are now off.
    await _repo.disableAlarms(await _platform.takeFiredOnce());
    final List<Alarm> alarms = await _repo.getAlarms();
    await _platform.syncAlarms(<Map<String, Object?>>[
      for (final Alarm a in alarms) a.toNative(),
    ]);
    return alarms;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Creates [alarm] when its id is 0, otherwise updates it.
  Future<Alarm> save(Alarm alarm) async {
    final Alarm saved;
    if (alarm.id == 0) {
      saved = await _repo.createAlarm(alarm);
    } else {
      await _repo.updateAlarm(alarm);
      saved = alarm;
    }
    await refresh();
    return saved;
  }

  Future<void> setEnabled(Alarm alarm, bool enabled) =>
      save(alarm.copyWith(enabled: enabled));

  Future<void> delete(Alarm alarm) async {
    await _repo.deleteAlarm(alarm.id);
    await refresh();
  }

  Future<void> test(Alarm alarm) => _platform.testAlarm(alarm.toNative());
}

final AsyncNotifierProvider<AlarmController, List<Alarm>>
alarmControllerProvider = AsyncNotifierProvider<AlarmController, List<Alarm>>(
  AlarmController.new,
);

class FocusState {
  const FocusState({
    required this.settings,
    required this.session,
    required this.todayFocusMs,
    required this.todayRounds,
  });

  final FocusSettings settings;
  final FocusSession? session;

  /// From sessions finished today.
  final int todayFocusMs;
  final int todayRounds;
}

/// The focus timer. The session is stored, so it carries on when the app is
/// closed; Android holds the phone and chimes phase changes meanwhile.
class FocusController extends AsyncNotifier<FocusState> {
  FocusRepository get _repo => ref.read(focusRepositoryProvider);
  FocusPlatform get _platform => ref.read(focusPlatformProvider);

  /// Whether this app last asked Android to pin it; unknown after a restart,
  /// so the first tick always tells Android.
  bool? _pinned;

  DateTime Function() clockNow = DateTime.now;

  /// Runs [tick] every second while a session exists, whatever is on
  /// screen, so light pinning and closing a finished session never stall.
  Timer? _ticker;

  /// True while a tick is running; overlapping ticks could log a finished
  /// session twice.
  bool _ticking = false;

  @override
  FutureOr<FocusState> build() {
    ref.onDispose(() => _ticker?.cancel());
    return _load();
  }

  /// The app came back to the front. Pinning may have been declined or
  /// escaped meanwhile, so light lockdown asks Android again.
  Future<void> resumed() async {
    _pinned = null;
    await tick();
  }

  void _keepTicking(bool on) {
    if (!on) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  Future<FocusState> _load() async {
    final DateTime now = clockNow();
    FocusSession? session = await _repo.getSession();
    if (session != null && session.isOver(now)) {
      await _finish(session, session.endsAt, early: false);
      session = null;
    }
    _keepTicking(session != null);
    return _state(await _repo.getSettings(), session, now);
  }

  Future<FocusState> _state(
    FocusSettings settings,
    FocusSession? session,
    DateTime now,
  ) async {
    final ({int focusMs, int rounds, int sessions}) today = await _repo
        .totalsSince(DateTime(now.year, now.month, now.day));
    return FocusState(
      settings: settings,
      session: session,
      todayFocusMs: today.focusMs,
      todayRounds: today.rounds,
    );
  }

  Future<void> _finish(
    FocusSession session,
    DateTime at, {
    required bool early,
  }) async {
    await _repo.logSession(
      startedAt: session.startedAt,
      endedAt: at,
      focusMs: session.focusMsUntil(at),
      rounds: session.roundsDoneAt(at),
      endedEarly: early,
    );
    await _repo.saveSession(null);
    await _platform.stopFocus();
    await _pin(false);
  }

  Future<void> _pin(bool pinned) async {
    if (_pinned == pinned) return;
    _pinned = pinned;
    await _platform.setPinned(pinned);
  }

  Future<void> _set(FocusSession? session) async {
    final DateTime now = clockNow();
    await _repo.saveSession(session);
    if (session == null || session.paused) {
      await _platform.stopFocus();
    } else {
      await _platform.startFocus(session.toNative());
    }
    state = AsyncData(await _state(await _repo.getSettings(), session, now));
    _keepTicking(session != null);
    await tick();
  }

  Future<void> saveSettings(FocusSettings settings) async {
    await _repo.saveSettings(settings);
    final FocusState? current = state.value;
    state = AsyncData(await _state(settings, current?.session, clockNow()));
  }

  Future<void> start() async {
    final FocusSettings settings = await _repo.getSettings();
    await _set(startSession(settings, clockNow()));
  }

  Future<void> pause() async {
    final FocusSession? session = state.value?.session;
    if (session == null) return;
    await _set(session.pause(clockNow()));
  }

  Future<void> resume() async {
    final FocusSession? session = state.value?.session;
    if (session == null) return;
    await _set(session.resume(clockNow()));
  }

  Future<void> skip() async {
    final FocusSession? session = state.value?.session;
    if (session == null) return;
    final FocusSession next = session.skip(clockNow());
    if (next.isOver(clockNow())) {
      await stop();
    } else {
      await _set(next);
    }
  }

  /// Ends the session now and records what was done.
  Future<void> stop() async {
    final FocusSession? session = state.value?.session;
    if (session == null || _ticking) return;
    _ticking = true;
    try {
      final DateTime now = clockNow();
      _keepTicking(false);
      await _finish(session, now, early: !session.isOver(now));
      state = AsyncData(await _state(await _repo.getSettings(), null, now));
    } finally {
      _ticking = false;
    }
  }

  /// Closes a finished session and pins or unpins the app for light
  /// lockdown. Runs every second while a session exists.
  Future<void> tick() async {
    if (_ticking) return;
    _ticking = true;
    try {
      final FocusState? current = state.value;
      final FocusSession? session = current?.session;
      final DateTime now = clockNow();
      if (session == null) {
        _keepTicking(false);
        return await _pin(false);
      }
      if (session.isOver(now)) {
        _keepTicking(false);
        await _finish(session, session.endsAt, early: false);
        state = AsyncData(await _state(current!.settings, null, now));
        return;
      }
      await _pin(
        session.settings.lockdown == Lockdown.light && session.lockedAt(now),
      );
    } finally {
      _ticking = false;
    }
  }
}

final AsyncNotifierProvider<FocusController, FocusState>
focusControllerProvider = AsyncNotifierProvider<FocusController, FocusState>(
  FocusController.new,
);

/// Ticks once a second for countdowns; stops when nothing shows one.
final StreamProvider<DateTime> secondsProvider =
    StreamProvider.autoDispose<DateTime>(
      (ref) => Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
    );

/// Ticks every 30 seconds for "rings in" labels.
final StreamProvider<DateTime> minutesProvider =
    StreamProvider.autoDispose<DateTime>(
      (ref) => Stream<DateTime>.periodic(
        const Duration(seconds: 30),
        (_) => DateTime.now(),
      ),
    );

/// Alarms snoozed right now (id to the time they ring again). Read again
/// whenever the alarm list changes or the app comes back to the front.
final FutureProvider<Map<int, DateTime>> alarmSnoozesProvider =
    FutureProvider<Map<int, DateTime>>((ref) {
      ref.watch(alarmControllerProvider);
      return ref.read(focusPlatformProvider).snoozes();
    });

/// Android phone settings, read again whenever asked.
final FutureProvider<PhoneReadiness> readinessProvider =
    FutureProvider<PhoneReadiness>(
      (ref) => ref.read(focusPlatformProvider).readiness(),
    );
