import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../focus/focus_controller.dart';
import '../focus/focus_platform.dart';

/// How long before an event it reminds, in minutes; null for no reminder.
const List<({int? minutes, String label})> reminderChoices =
    <({int? minutes, String label})>[
      (minutes: null, label: 'None'),
      (minutes: 0, label: 'At start'),
      (minutes: 5, label: '5 min before'),
      (minutes: 10, label: '10 min before'),
      (minutes: 15, label: '15 min before'),
      (minutes: 30, label: '30 min before'),
      (minutes: 60, label: '1 hour before'),
      (minutes: 1440, label: '1 day before'),
    ];

/// The default for a new event.
const int defaultReminderMinutes = 10;

/// The default for a new exam or assignment: the day before.
const int examReminderMinutes = 1440;

/// "Remind me" dropdown, with a one-line hint when Android has notifications
/// off so the reminder would never show.
class ReminderField extends ConsumerWidget {
  const ReminderField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  // The dropdown needs a non-null value to tell "None" from "nothing chosen".
  static const int _none = -1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final PhoneReadiness? ready = ref.watch(readinessProvider).value;
    final bool notificationsOff =
        value != null && ready?.notifications == false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButtonFormField<int>(
          key: const ValueKey<String>('reminder-field'),
          initialValue: value ?? _none,
          decoration: const InputDecoration(
            labelText: 'Remind me',
            prefixIcon: Icon(Icons.notifications_none_rounded),
            border: OutlineInputBorder(borderRadius: AppRadius.medium),
          ),
          items: <DropdownMenuItem<int>>[
            for (final ({int? minutes, String label}) c in reminderChoices)
              DropdownMenuItem<int>(
                value: c.minutes ?? _none,
                child: Text(c.label),
              ),
          ],
          onChanged: (int? v) {
            if (v != null) onChanged(v == _none ? null : v);
          },
        ),
        if (notificationsOff)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.notifications_off_outlined,
                  size: AppSizes.iconSm,
                  color: colors.error,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    'Notifications are off',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(focusPlatformProvider)
                      .openSetting('notifications'),
                  child: const Text('Turn on'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
