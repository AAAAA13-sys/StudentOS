import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What Android reports for one stretch of time.
class UsageRange {
  const UsageRange({
    required this.apps,
    required this.screenOn,
    required this.unlocks,
    required this.eventCount,
  });

  factory UsageRange.fromMap(Map<Object?, Object?> map) {
    DateTime at(Object? ms) =>
        DateTime.fromMillisecondsSinceEpoch((ms! as num).toInt());
    return UsageRange(
      apps: <AppUsage>[
        for (final Object? raw
            in (map['apps'] as List<Object?>? ?? <Object?>[]))
          if (raw is Map<Object?, Object?>)
            AppUsage(
              package: raw['package']! as String,
              label: raw['label']! as String,
              ms: (raw['ms']! as num).toInt(),
            ),
      ],
      screenOn: <(DateTime, DateTime)>[
        for (final Object? raw
            in (map['screenOn'] as List<Object?>? ?? <Object?>[]))
          if (raw is List<Object?> && raw.length == 2) (at(raw[0]), at(raw[1])),
      ],
      unlocks: <DateTime>[
        for (final Object? raw
            in (map['unlocks'] as List<Object?>? ?? <Object?>[]))
          at(raw),
      ],
      eventCount: (map['events'] as num?)?.toInt() ?? 0,
    );
  }

  final List<AppUsage> apps;

  /// Times the screen was on, in order.
  final List<(DateTime, DateTime)> screenOn;

  final List<DateTime> unlocks;

  /// How many usage events Android still had for the range. Zero for a past
  /// day means Android has already forgotten it, not that the phone was idle.
  final int eventCount;
}

class AppUsage {
  const AppUsage({
    required this.package,
    required this.label,
    required this.ms,
  });

  final String package;
  final String label;
  final int ms;
}

/// Where phone use comes from; replaced by a fake in tests.
abstract class PhoneUsageSource {
  Future<bool> hasAccess();

  /// Opens the system screen where Usage access is turned on.
  Future<bool> openAccessSettings();

  /// Null when Android refuses to answer (no access, or the phone is locked).
  Future<UsageRange?> query(DateTime start, DateTime end);
}

class ChannelPhoneUsageSource implements PhoneUsageSource {
  const ChannelPhoneUsageSource();

  static const MethodChannel _channel = MethodChannel('com.studentos/usage');

  @override
  Future<bool> hasAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> openAccessSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openUsageAccessSettings') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<UsageRange?> query(DateTime start, DateTime end) async {
    try {
      final Map<Object?, Object?>? map = await _channel
          .invokeMethod<Map<Object?, Object?>>('queryRange', <String, Object>{
            'startMs': start.millisecondsSinceEpoch,
            'endMs': end.millisecondsSinceEpoch,
          });
      return map == null ? null : UsageRange.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

final Provider<PhoneUsageSource> phoneUsageSourceProvider =
    Provider<PhoneUsageSource>((ref) => const ChannelPhoneUsageSource());
