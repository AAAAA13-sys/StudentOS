/// What it takes to turn a ringing alarm off.
enum AlarmChallenge {
  none('none', 'Just a button'),
  math('math', 'Solve maths'),
  type('type', 'Type a sentence'),
  shake('shake', 'Shake the phone');

  const AlarmChallenge(this.key, this.label);

  final String key;
  final String label;

  static AlarmChallenge fromKey(String key) => AlarmChallenge.values.firstWhere(
    (AlarmChallenge c) => c.key == key,
    orElse: () => math,
  );
}

enum MathDifficulty {
  easy('easy', 'Easy', '47 + 38'),
  medium('medium', 'Medium', '7 × 16 + 43'),
  hard('hard', 'Hard', '23 × 17 + 8 × 11');

  const MathDifficulty(this.key, this.label, this.example);

  final String key;
  final String label;
  final String example;

  static MathDifficulty fromKey(String key) => MathDifficulty.values.firstWhere(
    (MathDifficulty d) => d.key == key,
    orElse: () => medium,
  );
}

/// Sentence typed to turn off an alarm when the owner has not set one.
const String defaultAlarmPhrase = 'I am awake and I am getting up now';

/// One wake-up alarm with every setting that makes it hard to sleep through.
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.days = 0,
    this.label = '',
    this.enabled = true,
    this.soundUri,
    this.soundName,
    this.volume = 100,
    this.rampSeconds = 0,
    this.volumeLock = true,
    this.vibrate = true,
    this.challenge = AlarmChallenge.math,
    this.challengeCount = 3,
    this.difficulty = MathDifficulty.medium,
    this.phrase = '',
    this.snoozeLimit = 1,
    this.snoozeMinutes = 5,
    this.wakeCheck = true,
    this.wakeCheckMinutes = 5,
  });

  final int id;
  final int hour;
  final int minute;

  /// Bit 0 is Monday ... bit 6 is Sunday; zero rings once.
  final int days;
  final String label;
  final bool enabled;
  final String? soundUri;
  final String? soundName;
  final int volume;
  final int rampSeconds;
  final bool volumeLock;
  final bool vibrate;
  final AlarmChallenge challenge;
  final int challengeCount;
  final MathDifficulty difficulty;
  final String phrase;
  final int snoozeLimit;
  final int snoozeMinutes;
  final bool wakeCheck;
  final int wakeCheckMinutes;

  bool get repeats => days != 0;

  /// Whether it rings on [weekday] (`DateTime.monday` .. `DateTime.sunday`).
  bool ringsOn(int weekday) => days & (1 << (weekday - 1)) != 0;

  String get effectivePhrase =>
      phrase.trim().isEmpty ? defaultAlarmPhrase : phrase.trim();

  /// The next time it rings after [now]; null when it is off.
  DateTime? nextRing(DateTime now) {
    if (!enabled) return null;
    for (int ahead = 0; ahead <= 7; ahead++) {
      final DateTime at = DateTime(
        now.year,
        now.month,
        now.day + ahead,
        hour,
        minute,
      );
      if (!at.isAfter(now)) continue;
      if (!repeats || ringsOn(at.weekday)) return at;
    }
    return null;
  }

  /// `Every day`, `Weekdays`, `Mon, Wed, Fri`, or `Once`.
  String get daysLabel {
    if (days == 0) return 'Once';
    if (days == 0x7F) return 'Every day';
    if (days == 0x1F) return 'Weekdays';
    if (days == 0x60) return 'Weekends';
    const List<String> names = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return <String>[
      for (int i = 0; i < 7; i++)
        if (days & (1 << i) != 0) names[i],
    ].join(', ');
  }

  /// What turning it off takes, in a few words.
  String get challengeSummary => switch (challenge) {
    AlarmChallenge.none => 'Button to stop',
    AlarmChallenge.math =>
      '$challengeCount ${difficulty.label.toLowerCase()} '
          '${challengeCount == 1 ? 'sum' : 'sums'}',
    AlarmChallenge.type => 'Type a sentence',
    AlarmChallenge.shake => 'Shake $challengeCount times',
  };

  /// The form the Android side reads; keys match `AlarmStore.kt`.
  Map<String, Object?> toNative() => <String, Object?>{
    'id': id,
    'hour': hour,
    'minute': minute,
    'days': days,
    'label': label,
    'enabled': enabled,
    'soundUri': soundUri,
    'soundName': soundName,
    'volume': volume,
    'rampSeconds': rampSeconds,
    'volumeLock': volumeLock,
    'vibrate': vibrate,
    'challenge': challenge.key,
    'challengeCount': challengeCount,
    'difficulty': difficulty.key,
    'phrase': effectivePhrase,
    'snoozeLimit': snoozeLimit,
    'snoozeMinutes': snoozeMinutes,
    'wakeCheck': wakeCheck,
    'wakeCheckMinutes': wakeCheckMinutes,
  };

  Alarm copyWith({
    int? id,
    int? hour,
    int? minute,
    int? days,
    String? label,
    bool? enabled,
    String? soundUri,
    String? soundName,
    bool clearSound = false,
    int? volume,
    int? rampSeconds,
    bool? volumeLock,
    bool? vibrate,
    AlarmChallenge? challenge,
    int? challengeCount,
    MathDifficulty? difficulty,
    String? phrase,
    int? snoozeLimit,
    int? snoozeMinutes,
    bool? wakeCheck,
    int? wakeCheckMinutes,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      soundUri: clearSound ? null : soundUri ?? this.soundUri,
      soundName: clearSound ? null : soundName ?? this.soundName,
      volume: volume ?? this.volume,
      rampSeconds: rampSeconds ?? this.rampSeconds,
      volumeLock: volumeLock ?? this.volumeLock,
      vibrate: vibrate ?? this.vibrate,
      challenge: challenge ?? this.challenge,
      challengeCount: challengeCount ?? this.challengeCount,
      difficulty: difficulty ?? this.difficulty,
      phrase: phrase ?? this.phrase,
      snoozeLimit: snoozeLimit ?? this.snoozeLimit,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      wakeCheck: wakeCheck ?? this.wakeCheck,
      wakeCheckMinutes: wakeCheckMinutes ?? this.wakeCheckMinutes,
    );
  }
}

/// `in 7 h 20 min`, `in 45 min`, `in less than a minute`.
String ringsIn(Duration d) {
  if (d.inSeconds < 60) return 'in less than a minute';
  final int minutes = (d.inSeconds / 60).ceil();
  final int days = minutes ~/ (24 * 60);
  final int h = (minutes % (24 * 60)) ~/ 60;
  final int m = minutes % 60;
  final List<String> parts = <String>[
    if (days > 0) '$days d',
    if (h > 0) '$h h',
    if (m > 0 && days == 0) '$m min',
  ];
  return 'in ${parts.join(' ')}';
}
