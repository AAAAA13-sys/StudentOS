import 'dart:convert';

/// What a focus session can be aimed at.
enum FocusTargetType {
  task('task'),
  event('event'),
  recall('recall');

  const FocusTargetType(this.key);

  final String key;

  static FocusTargetType? fromKey(String? key) {
    for (final FocusTargetType value in FocusTargetType.values) {
      if (value.key == key) return value;
    }
    return null;
  }
}

/// Optional target bound to a focus session before or while running.
class FocusIntention {
  const FocusIntention({required this.type, this.id, required this.label});

  final FocusTargetType type;
  final int? id;
  final String label;

  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.key,
    if (id != null) 'id': id,
    'label': label,
  };

  String toJsonString() => jsonEncode(toJson());

  static FocusIntention? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) return null;
      final FocusTargetType? type = FocusTargetType.fromKey(
        decoded['type'] as String?,
      );
      final String? label = (decoded['label'] as String?)?.trim();
      if (type == null || label == null || label.isEmpty) return null;
      final int? id = (decoded['id'] as num?)?.toInt();
      return FocusIntention(type: type, id: id, label: label);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FocusIntention &&
      other.type == type &&
      other.id == id &&
      other.label == label;

  @override
  int get hashCode => Object.hash(type, id, label);
}

/// One finished focus session recorded in the local database.
class FocusLog {
  const FocusLog({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.focusMs,
    required this.rounds,
    required this.endedEarly,
    this.intention,
  });

  final int id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int focusMs;
  final int rounds;
  final bool endedEarly;
  final FocusIntention? intention;
}

/// How hard a focus phase holds the phone.
enum Lockdown {
  off('off', 'Off', 'Timer only. Nothing is blocked.'),
  light(
    'light',
    'Light',
    "Pins StudentOS to the screen. Android's own unpin gesture gets you out "
        '(swipe up and hold, or hold Back and Overview).',
  ),
  strict(
    'strict',
    'Strict',
    'Any app not on your list sends you straight back here. Calls still '
        'work. Stopping early means typing your exit sentence.',
  );

  const Lockdown(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;

  static Lockdown fromKey(String? key) => Lockdown.values.firstWhere(
    (Lockdown l) => l.key == key,
    orElse: () => light,
  );
}

enum PhaseKind {
  focus('focus', 'Focus'),
  shortBreak('short', 'Short break'),
  longBreak('long', 'Long break');

  const PhaseKind(this.key, this.label);

  final String key;
  final String label;

  bool get isBreak => this != focus;

  static PhaseKind fromKey(String key) =>
      PhaseKind.values.firstWhere((PhaseKind k) => k.key == key);
}

const String defaultExitPhrase = 'I am choosing to stop focusing right now';

/// The owner's Pomodoro setup. One round with no breaks is a plain timer.
class FocusSettings {
  const FocusSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.rounds = 4,
    this.longBreakEvery = 4,
    this.lockdown = Lockdown.light,
    this.allowedApps = const <String>[],
    this.exitPhrase = defaultExitPhrase,
    this.chime = true,
  });

  factory FocusSettings.fromJson(Map<String, Object?> json) {
    int whole(String key, int fallback, int min, int max) {
      final Object? v = json[key];
      return v is num ? v.toInt().clamp(min, max) : fallback;
    }

    return FocusSettings(
      focusMinutes: whole('focusMinutes', 25, 1, 240),
      shortBreakMinutes: whole('shortBreakMinutes', 5, 0, 60),
      longBreakMinutes: whole('longBreakMinutes', 15, 0, 120),
      rounds: whole('rounds', 4, 1, 12),
      longBreakEvery: whole('longBreakEvery', 4, 2, 12),
      lockdown: Lockdown.fromKey(json['lockdown'] as String?),
      allowedApps: <String>[
        for (final Object? p in (json['allowedApps'] as List<Object?>? ?? []))
          if (p is String) p,
      ],
      exitPhrase: (json['exitPhrase'] as String?)?.trim().isNotEmpty == true
          ? (json['exitPhrase']! as String).trim()
          : defaultExitPhrase,
      chime: json['chime'] as bool? ?? true,
    );
  }

  final int focusMinutes;

  /// 0 skips the break.
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int rounds;

  /// A long break replaces the short one after every this many rounds.
  final int longBreakEvery;
  final Lockdown lockdown;

  /// Package names that strict lockdown lets through.
  final List<String> allowedApps;
  final String exitPhrase;

  /// Sound and vibration when a phase changes.
  final bool chime;

  Map<String, Object?> toJson() => <String, Object?>{
    'focusMinutes': focusMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'rounds': rounds,
    'longBreakEvery': longBreakEvery,
    'lockdown': lockdown.key,
    'allowedApps': allowedApps,
    'exitPhrase': exitPhrase,
    'chime': chime,
  };

  FocusSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? rounds,
    int? longBreakEvery,
    Lockdown? lockdown,
    List<String>? allowedApps,
    String? exitPhrase,
    bool? chime,
  }) => FocusSettings(
    focusMinutes: focusMinutes ?? this.focusMinutes,
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    rounds: rounds ?? this.rounds,
    longBreakEvery: longBreakEvery ?? this.longBreakEvery,
    lockdown: lockdown ?? this.lockdown,
    allowedApps: allowedApps ?? this.allowedApps,
    exitPhrase: exitPhrase ?? this.exitPhrase,
    chime: chime ?? this.chime,
  );

  /// The phases of a session in order, before any start time is known.
  List<(PhaseKind, Duration)> get sequence => <(PhaseKind, Duration)>[
    for (int round = 1; round <= rounds; round++) ...<(PhaseKind, Duration)>[
      (PhaseKind.focus, Duration(minutes: focusMinutes)),
      // No break after the last round: the session is over.
      if (round < rounds)
        if (round % longBreakEvery == 0 && longBreakMinutes > 0)
          (PhaseKind.longBreak, Duration(minutes: longBreakMinutes))
        else if (round % longBreakEvery != 0 && shortBreakMinutes > 0)
          (PhaseKind.shortBreak, Duration(minutes: shortBreakMinutes)),
    ],
  ];
}

class FocusPhase {
  const FocusPhase(this.kind, this.start, this.end, this.round);

  factory FocusPhase.fromJson(Map<String, Object?> json) => FocusPhase(
    PhaseKind.fromKey(json['kind']! as String),
    DateTime.fromMillisecondsSinceEpoch((json['start']! as num).toInt()),
    DateTime.fromMillisecondsSinceEpoch((json['end']! as num).toInt()),
    (json['round']! as num).toInt(),
  );

  final PhaseKind kind;
  final DateTime start;
  final DateTime end;

  /// 1-based focus round this phase belongs to (a break shares its round).
  final int round;

  Duration get length => end.difference(start);

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.key,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'round': round,
  };
}

/// Lays [sequence] out back to back from [start].
List<FocusPhase> layOut(List<(PhaseKind, Duration)> sequence, DateTime start) {
  final List<FocusPhase> phases = <FocusPhase>[];
  DateTime at = start;
  int round = 0;
  for (final (PhaseKind kind, Duration length) in sequence) {
    if (kind == PhaseKind.focus) round++;
    phases.add(FocusPhase(kind, at, at.add(length), round));
    at = at.add(length);
  }
  return phases;
}

/// A focus session in progress. While paused, [pausedAt] is set and the
/// phases still carry the times they had when it was paused.
class FocusSession {
  const FocusSession({
    required this.startedAt,
    required this.phases,
    required this.settings,
    this.pausedAt,
    this.focusBankedMs = 0,
  });

  factory FocusSession.fromJson(Map<String, Object?> json) => FocusSession(
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['startedAt']! as num).toInt(),
    ),
    phases: <FocusPhase>[
      for (final Object? p in json['phases']! as List<Object?>)
        FocusPhase.fromJson((p! as Map<Object?, Object?>).cast()),
    ],
    settings: FocusSettings.fromJson(
      (json['settings']! as Map<Object?, Object?>).cast(),
    ),
    pausedAt: json['pausedAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            (json['pausedAt']! as num).toInt(),
          ),
    focusBankedMs: (json['focusBankedMs'] as num?)?.toInt() ?? 0,
  );

  static FocusSession? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return FocusSession.fromJson(
        (jsonDecode(raw) as Map<Object?, Object?>).cast(),
      );
    } catch (_) {
      return null;
    }
  }

  final DateTime startedAt;
  final List<FocusPhase> phases;
  final FocusSettings settings;
  final DateTime? pausedAt;

  /// Focus time from phases that were cut short by a pause or skip and are
  /// no longer in [phases] with their original length.
  final int focusBankedMs;

  bool get paused => pausedAt != null;

  DateTime get endsAt => phases.last.end;

  int get totalRounds =>
      phases.where((FocusPhase p) => p.kind == PhaseKind.focus).length;

  /// The phase running at [now] (or at the pause); null once it is over.
  FocusPhase? phaseAt(DateTime now) {
    final DateTime at = pausedAt ?? now;
    for (final FocusPhase phase in phases) {
      if (!at.isBefore(phase.start) && at.isBefore(phase.end)) return phase;
    }
    return null;
  }

  bool isOver(DateTime now) => !paused && !now.isBefore(endsAt);

  Duration remaining(DateTime now) {
    final FocusPhase? phase = phaseAt(now);
    if (phase == null) return Duration.zero;
    return phase.end.difference(pausedAt ?? now);
  }

  /// Focus time spent so far, not counting breaks or pauses.
  int focusMsUntil(DateTime now) {
    final DateTime at = pausedAt ?? now;
    int ms = focusBankedMs;
    for (final FocusPhase p in phases) {
      if (p.kind != PhaseKind.focus || !at.isAfter(p.start)) continue;
      // A skipped phase has no length; its time is already in the bank.
      final DateTime to = at.isBefore(p.end) ? at : p.end;
      ms += to.difference(p.start).inMilliseconds;
    }
    return ms;
  }

  /// Focus rounds finished in full by [now].
  int roundsDoneAt(DateTime now) {
    final DateTime at = pausedAt ?? now;
    return phases
        .where(
          (FocusPhase p) =>
              p.kind == PhaseKind.focus &&
              p.end.isAfter(p.start) &&
              !at.isBefore(p.end),
        )
        .length;
  }

  /// True while a focus phase is running and the phone is meant to be held.
  bool lockedAt(DateTime now) =>
      !paused &&
      settings.lockdown != Lockdown.off &&
      phaseAt(now)?.kind == PhaseKind.focus;

  FocusSession pause(DateTime now) => paused
      ? this
      : FocusSession(
          startedAt: startedAt,
          phases: phases,
          settings: settings,
          pausedAt: now,
          focusBankedMs: focusBankedMs,
        );

  /// Shifts every phase that has not finished by the length of the pause.
  FocusSession resume(DateTime now) {
    final DateTime? at = pausedAt;
    if (at == null) return this;
    final Duration gap = now.difference(at);
    return FocusSession(
      startedAt: startedAt,
      phases: <FocusPhase>[
        for (final FocusPhase p in phases)
          if (!at.isBefore(p.end))
            p
          else if (!at.isBefore(p.start))
            // The paused phase: the part already done stays where it was.
            FocusPhase(p.kind, p.start, p.end.add(gap), p.round)
          else
            FocusPhase(p.kind, p.start.add(gap), p.end.add(gap), p.round),
      ],
      settings: settings,
      focusBankedMs: focusBankedMs,
    );
  }

  /// Ends the current phase now and starts the next one straight away. A
  /// skipped phase stays in the list with no length, so it never counts as a
  /// finished round; focus time already spent in it is kept.
  FocusSession skip(DateTime now) {
    final FocusSession running = resume(now);
    final FocusPhase? current = running.phaseAt(now);
    if (current == null) return running;
    final int index = running.phases.indexOf(current);
    final Duration cut = current.end.difference(now);
    final int banked = current.kind == PhaseKind.focus
        ? now.difference(current.start).inMilliseconds
        : 0;
    return FocusSession(
      startedAt: startedAt,
      phases: <FocusPhase>[
        for (int i = 0; i < running.phases.length; i++)
          if (i < index)
            running.phases[i]
          else if (i == index)
            FocusPhase(current.kind, now, now, current.round)
          else
            FocusPhase(
              running.phases[i].kind,
              running.phases[i].start.subtract(cut),
              running.phases[i].end.subtract(cut),
              running.phases[i].round,
            ),
      ],
      settings: settings,
      focusBankedMs: focusBankedMs + banked,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'startedAt': startedAt.millisecondsSinceEpoch,
    'phases': <Object?>[for (final FocusPhase p in phases) p.toJson()],
    'settings': settings.toJson(),
    'pausedAt': pausedAt?.millisecondsSinceEpoch,
    'focusBankedMs': focusBankedMs,
  };

  String encode() => jsonEncode(toJson());

  /// What the Android side needs to hold the phone and ring phase changes.
  Map<String, Object?> toNative() => <String, Object?>{
    'phases': <Object?>[
      for (final FocusPhase p in phases)
        if (p.end.isAfter(p.start)) p.toJson(),
    ],
    'lockdown': settings.lockdown.key,
    'allowedApps': settings.allowedApps,
    'chime': settings.chime,
  };
}

/// A new session laid out from [now].
FocusSession startSession(FocusSettings settings, DateTime now) => FocusSession(
  startedAt: now,
  phases: layOut(settings.sequence, now),
  settings: settings,
);

/// `24:59`, `1:04:05`.
String clock(Duration d) {
  final int s = d.inSeconds < 0 ? 0 : d.inSeconds;
  final int h = s ~/ 3600;
  final String mm = ((s % 3600) ~/ 60).toString().padLeft(h > 0 ? 2 : 1, '0');
  final String ss = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
