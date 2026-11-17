import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hands Android the upcoming event reminders; replaced by a fake in tests.
abstract class ReminderPlatform {
  /// Replaces every stored reminder with [reminders] (`ReminderFire.toNative`).
  Future<void> sync(List<Map<String, Object?>> reminders);
}

class ChannelReminderPlatform implements ReminderPlatform {
  const ChannelReminderPlatform();

  static const MethodChannel _channel = MethodChannel(
    'com.studentos/reminders',
  );

  @override
  Future<void> sync(List<Map<String, Object?>> reminders) async {
    try {
      await _channel.invokeMethod<void>('syncReminders', <String, Object?>{
        'reminders': reminders,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}

final Provider<ReminderPlatform> reminderPlatformProvider =
    Provider<ReminderPlatform>((ref) => const ChannelReminderPlatform());
