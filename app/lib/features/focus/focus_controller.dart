import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../phone/phone_day.dart';
import '../phone/phone_repository.dart';
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

class FocusCompletionPrompt {
  const FocusCompletionPrompt({
    required this.intention,
    required this.focusedMs,
  });

  final FocusIntention intention;
  final int focusedMs;
}

class FocusState {
  const FocusState({
    required this.settings,
    required this.session,
    required this.todayFocusMs,
    required this.todayRounds,
    this.intention,
    this.completionPrompt,
    this.latestRun,
    this.todayTargets = const <({String label, int focusMs})>[],
    this.showMicroSprint = false,
  });

  final FocusSettings settings;
  final FocusSession? session;

  /// From sessions finished today.
  final int todayFocusMs;
  final int todayRounds;

  final FocusIntention? intention;
  final FocusCompletionPrompt? completionPrompt;
  final FocusLog? latestRun;
  final List<({String label, int focusMs})> todayTargets;
  final bool showMicroSprint;

  FocusState copyWith({
    FocusSettings? settings,
    FocusSession? session,
    bool clearSession = false,
    int? todayFocusMs,
    int? todayRounds,
    FocusIntention? intention,
    bool clearIntention = false,
    FocusCompletionPrompt? completionPrompt,
    bool clearCompletionPrompt = false,
    FocusLog? latestRun,
    List<({String label, int focusMs})>? todayTargets,
    bool? showMicroSprint,
  }) => FocusState(
    settings: settings ?? this.settings,
    session: clearSession ? null : (session ?? this.session),
    todayFocusMs: todayFocusMs ?? this.todayFocusMs,
    todayRounds: todayRounds ?? this.todayRounds,
    intention: clearIntention ? null : (intention ?? this.intention),
    completionPrompt: clearCompletionPrompt
        ? null
        : (completionPrompt ?? this.completionPrompt),
    latestRun: latestRun ?? this.latestRun,
    todayTargets: todayTargets ?? this.todayTargets,
    showMicroSprint: showMicroSprint ?? this.showMicroSprint,
  );
}

/// The focus timer. The session is stored, so it carries on when the app is
/// closed; Android holds the phone and chimes phase changes meanwhile.
class FocusController extends AsyncNotifier<FocusState> {
  FocusRepository get _repo => ref.read(focusRepositoryProvider);
  PhoneRepository get _phoneRepo => ref.read(phoneRepositoryProvider);
  FocusPlatform get _platform => ref.read(focusPlatformProvider);

  static const Duration _lowRestThreshold = Duration(minutes: 330);

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

  FocusCompletionPrompt? _completionPrompt;

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
    if (!ref.mounted) return _emptyState();
    if (session != null && session.isOver(now)) {
      await _finish(session, session.endsAt, early: false);
      if (!ref.mounted) return _emptyState();
      session = null;
    }
    _keepTicking(session != null);
    final FocusSettings settings = await _repo.getSettings();
    if (!ref.mounted) return _emptyState();
    return _state(settings, session, now);
  }

  static FocusState _emptyState() => const FocusState(
    settings: FocusSettings(),
    session: null,
    todayFocusMs: 0,
    todayRounds: 0,
  );

  Future<bool> _hasLowRest(DateTime now) async {
    final DateTime from = DateTime(now.year, now.month, now.day - 1);
    final List<PhoneDay> days = await _phoneRepo.getDays(from);
    if (!ref.mounted) return false;
    Duration? latestRest;
    for (final PhoneDay day in days) {
      if (day.rest != null) latestRest = day.rest;
    }
    return latestRest != null && latestRest < _lowRestThreshold;
  }

  Future<FocusState> _state(
    FocusSettings settings,
    FocusSession? session,
    DateTime now,
  ) async {
    final DateTime dayStart = DateTime(now.year, now.month, now.day);
    final ({int focusMs, int rounds, int sessions}) today = await _repo
        .totalsSince(dayStart);
    if (!ref.mounted) return _emptyState();
    final FocusIntention? intention = await _repo.getIntention();
    if (!ref.mounted) return _emptyState();
    final FocusLog? latestRun = await _repo.latestLog();
    if (!ref.mounted) return _emptyState();
    final List<({String label, int focusMs})> todayTargets = await _repo
        .todayByTarget(dayStart);
    if (!ref.mounted) return _emptyState();
    final bool lowRest = await _hasLowRest(now);
    if (!ref.mounted) return _emptyState();
    final bool showMicroSprint =
        settings.focusMinutes > 20 ||
        (latestRun?.endedEarly ?? false) ||
        lowRest;
    return FocusState(
      settings: settings,
      session: session,
      todayFocusMs: today.focusMs,
      todayRounds: today.rounds,
      intention: intention,
      completionPrompt: _completionPrompt,
      latestRun: latestRun,
      todayTargets: todayTargets,
      showMicroSprint: showMicroSprint,
    );
  }

  Future<void> _finish(
    FocusSession session,
    DateTime at, {
    required bool early,
  }) async {
    final FocusIntention? currentIntention =
        state.value?.intention ?? await _repo.getIntention();
    if (!ref.mounted) return;
    final int workedMs = session.focusMsUntil(at);
    await _repo.logSession(
      startedAt: session.startedAt,
      endedAt: at,
      focusMs: workedMs,
      rounds: session.roundsDoneAt(at),
      endedEarly: early,
      intention: currentIntention,
    );
    if (!ref.mounted) return;
    await _repo.saveSession(null);
    if (!ref.mounted) return;
    await _repo.saveIntention(null);
    if (!ref.mounted) return;
    await _platform.stopFocus();
    if (!ref.mounted) return;
    await _pin(false);
    if (!ref.mounted) return;
    _completionPrompt =
        currentIntention != null &&
            workedMs >= const Duration(minutes: 1).inMilliseconds
        ? FocusCompletionPrompt(
            intention: currentIntention,
            focusedMs: workedMs,
          )
        : null;
  }

  Future<void> _pin(bool pinned) async {
    if (_pinned == pinned) return;
    _pinned = pinned;
    await _platform.setPinned(pinned);
  }

  Future<void> _set(FocusSession? session) async {
    final DateTime now = clockNow();
    await _repo.saveSession(session);
    if (!ref.mounted) return;
    if (session == null || session.paused) {
      await _platform.stopFocus();
    } else {
      await _platform.startFocus(session.toNative());
    }
    if (!ref.mounted) return;
    final FocusSettings savedSettings = await _repo.getSettings();
    if (!ref.mounted) return;
    final FocusState next = await _state(savedSettings, session, now);
    if (!ref.mounted) return;
    state = AsyncData(next);
    _keepTicking(session != null);
    await tick();
  }

  Future<void> setIntention(FocusIntention? intention) async {
    if (state.hasValue) {
      state = AsyncData(
        state.requireValue.copyWith(
          intention: intention,
          clearIntention: intention == null,
        ),
      );
    }
    await _repo.saveIntention(intention);
    if (!ref.mounted) return;
    final FocusState current = state.value ?? await future;
    if (!ref.mounted) return;
    state = AsyncData(
      current.copyWith(
        intention: intention,
        clearIntention: intention == null,
      ),
    );
  }

  void dismissCompletionPrompt() {
    _completionPrompt = null;
    final FocusState? current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearCompletionPrompt: true));
  }

  Future<void> saveSettings(FocusSettings settings) async {
    await _repo.saveSettings(settings);
    if (!ref.mounted) return;
    final FocusState? current = state.value;
    final FocusState next = await _state(settings, current?.session, clockNow());
    if (!ref.mounted) return;
    state = AsyncData(next);
  }

  Future<void> start({FocusSettings? overrideSettings}) async {
    _completionPrompt = null;
    final FocusSettings settings =
        overrideSettings ?? state.value?.settings ?? await _repo.getSettings();
    if (!ref.mounted) return;
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
      if (!ref.mounted) return;
      final FocusSettings savedSettings = await _repo.getSettings();
      if (!ref.mounted) return;
      final FocusState next = await _state(savedSettings, null, now);
      if (!ref.mounted) return;
      state = AsyncData(next);
    } finally {
      _ticking = false;
    }
  }

  /// Closes a finished session and pins or unpins the app for light
  /// lockdown. Runs every second while a session exists.
  Future<void> tick() async {
    if (_ticking || !ref.mounted) return;
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
        if (!ref.mounted) return;
        final FocusState next = await _state(current!.settings, null, now);
        if (!ref.mounted) return;
        state = AsyncData(next);
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
