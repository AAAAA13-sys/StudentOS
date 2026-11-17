import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'event.dart';
import 'reminder_field.dart';

/// One weekly event per weekday in [weekdays] (`DateTime.monday` ..
/// `DateTime.sunday`), each starting on its first such day on or after
/// [from] and repeating through [until].
List<CalendarEvent> buildClassSchedule({
  required String title,
  required String? location,
  required Set<int> weekdays,
  required int hour,
  required int minute,
  required int durationMinutes,
  required DateTime from,
  required DateTime until,
  int? reminderMinutes,
}) {
  final String untilKey = DateFormat('yyyy-MM-dd').format(until);
  final List<int> ordered = weekdays.toList()..sort();
  return <CalendarEvent>[
    for (final int weekday in ordered)
      CalendarEvent(
        id: 0,
        title: title,
        startsAt: DateTime(
          from.year,
          from.month,
          from.day + (weekday - from.weekday) % 7,
          hour,
          minute,
        ),
        durationMinutes: durationMinutes,
        location: location,
        recurrence: 'weekly',
        recurrenceUntil: untilKey,
        reminderMinutes: reminderMinutes,
      ),
  ];
}

/// Asks for a class and the weekdays it meets; returns the events to save.
Future<List<CalendarEvent>?> showClassScheduleSheet(BuildContext context) {
  return showModalBottomSheet<List<CalendarEvent>>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => const _ClassScheduleSheet(),
  );
}

class _ClassScheduleSheet extends StatefulWidget {
  const _ClassScheduleSheet();

  @override
  State<_ClassScheduleSheet> createState() => _ClassScheduleSheetState();
}

class _ClassScheduleSheetState extends State<_ClassScheduleSheet> {
  static const List<(int, String)> _days = <(int, String)>[
    (DateTime.monday, 'Mon'),
    (DateTime.tuesday, 'Tue'),
    (DateTime.wednesday, 'Wed'),
    (DateTime.thursday, 'Thu'),
    (DateTime.friday, 'Fri'),
    (DateTime.saturday, 'Sat'),
    (DateTime.sunday, 'Sun'),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final Set<int> _weekdays = <int>{};
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _duration = 60;
  int? _reminder = defaultReminderMinutes;
  late DateTime _until;
  bool _showDayError = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _until = DateTime(now.year, now.month + 4, now.day);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    final bool formOk = _formKey.currentState!.validate();
    setState(() => _showDayError = _weekdays.isEmpty);
    if (!formOk || _weekdays.isEmpty) return;

    final String location = _location.text.trim();
    Navigator.pop(
      context,
      buildClassSchedule(
        title: _title.text.trim(),
        location: location.isEmpty ? null : location,
        weekdays: _weekdays,
        hour: _time.hour,
        minute: _time.minute,
        durationMinutes: _duration,
        from: DateTime.now(),
        until: _until,
        reminderMinutes: _reminder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: AppRadius.medium,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Add a class',
                style: textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                'Pick the days it meets. It repeats every week until the end date.',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Math 101',
                  border: border,
                ),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Subject required'
                    : null,
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Room (optional)',
                  border: border,
                ),
              ),
              AppSpacing.gapMd,
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (final (int weekday, String label) in _days)
                    FilterChip(
                      label: Text(label),
                      selected: _weekdays.contains(weekday),
                      onSelected: (bool selected) => setState(() {
                        if (selected) {
                          _weekdays.add(weekday);
                        } else {
                          _weekdays.remove(weekday);
                        }
                        _showDayError = false;
                      }),
                    ),
                ],
              ),
              if (_showDayError)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Pick at least one day',
                    style: textStyles.bodySmall?.copyWith(color: colors.error),
                  ),
                ),
              AppSpacing.gapMd,
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(_time.format(context)),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (picked != null) setState(() => _time = picked);
                      },
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _duration,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: border,
                      ),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(value: 60, child: Text('1 hour')),
                        DropdownMenuItem<int>(
                          value: 90,
                          child: Text('1.5 hours'),
                        ),
                        DropdownMenuItem<int>(
                          value: 120,
                          child: Text('2 hours'),
                        ),
                        DropdownMenuItem<int>(
                          value: 180,
                          child: Text('3 hours'),
                        ),
                      ],
                      onChanged: (int? value) {
                        if (value != null) setState(() => _duration = value);
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  'Until ${DateFormat('MMM d, yyyy').format(_until)}',
                ),
                onPressed: () async {
                  final DateTime now = DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _until,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: DateTime(now.year + 2, now.month, now.day),
                  );
                  if (picked != null) setState(() => _until = picked);
                },
              ),
              AppSpacing.gapMd,
              ReminderField(
                value: _reminder,
                onChanged: (int? v) => setState(() => _reminder = v),
              ),
              AppSpacing.gapXl,
              SizedBox(
                height: AppSizes.buttonHeight,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save class'),
                ),
              ),
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}
