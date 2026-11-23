import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../calendar/calendar_controller.dart';
import '../calendar/event.dart';
import 'shift.dart';
import 'work_controller.dart';

typedef _ShiftSheetResult = ({
  List<Shift>? shifts,
  bool delete,
  bool andLater,
});

/// Asks for a shift, saves it and says so. [day] is the date offered first.
Future<void> addShift(
  BuildContext context,
  WidgetRef ref, {
  DateTime? day,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final WorkController controller = ref.read(workControllerProvider.notifier);
  final List<Shift> known =
      ref.read(workControllerProvider).value ?? const <Shift>[];
  final List<CalendarEvent> events =
      ref.read(calendarControllerProvider).value ?? const <CalendarEvent>[];

  final _ShiftSheetResult? result =
      await showModalBottomSheet<_ShiftSheetResult>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext ctx) => _AddShiftSheet(
          day: day ?? DateTime.now(),
          last: known.isEmpty ? null : known.last,
          events: events,
        ),
      );
  final List<Shift>? shifts = result?.shifts;
  if (shifts == null || shifts.isEmpty) return;
  await controller.addShifts(shifts);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          shifts.length == 1
              ? 'Added a shift at ${shifts.first.job}'
              : 'Added ${shifts.length} shifts at ${shifts.first.job}',
        ),
      ),
    );
}

/// Asks for new details of [shift] and saves them, or deletes the shift.
Future<void> editShift(BuildContext context, WidgetRef ref, Shift shift) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final WorkController controller = ref.read(workControllerProvider.notifier);
  final List<CalendarEvent> events =
      ref.read(calendarControllerProvider).value ?? const <CalendarEvent>[];
  final _ShiftSheetResult? result =
      await showModalBottomSheet<_ShiftSheetResult>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext ctx) => _AddShiftSheet(
          day: shift.startsAt,
          last: shift,
          events: events,
          editing: shift,
        ),
      );
  if (result == null) return;
  if (result.delete) {
    await controller.deleteShift(shift, andLater: result.andLater);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.andLater
                ? 'Removed shifts at ${shift.job}'
                : 'Removed shift at ${shift.job}',
          ),
        ),
      );
    return;
  }
  final List<Shift>? shifts = result.shifts;
  if (shifts == null || shifts.isEmpty) return;
  await controller.updateShift(shifts.first);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('Updated shift at ${shifts.first.job}')),
    );
}

class _AddShiftSheet extends StatefulWidget {
  const _AddShiftSheet({
    required this.day,
    required this.last,
    required this.events,
    this.editing,
  });

  /// The shift being edited; null when adding.
  final Shift? editing;

  final DateTime day;

  /// The most recent shift; its workplace, times and rate are offered again.
  final Shift? last;

  /// Calendar events a shift could run into.
  final List<CalendarEvent> events;

  @override
  State<_AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<_AddShiftSheet> {
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
  late final TextEditingController _job;
  late final TextEditingController _rate;
  late DateTime _day;
  late DateTime _until;
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _repeats = false;
  final Set<int> _weekdays = <int>{};
  bool _showDayError = false;

  @override
  void initState() {
    super.initState();
    final Shift? last = widget.last;
    _job = TextEditingController(text: last?.job ?? '');
    _rate = TextEditingController(
      text: last == null || last.hourlyRateCents == 0
          ? ''
          : (last.hourlyRateCents / 100).toStringAsFixed(
              last.hourlyRateCents % 100 == 0 ? 0 : 2,
            ),
    );
    _day = DateTime(widget.day.year, widget.day.month, widget.day.day);
    _until = DateTime(_day.year, _day.month, _day.day + 27);
    _start = last == null
        ? const TimeOfDay(hour: 17, minute: 0)
        : TimeOfDay.fromDateTime(last.startsAt);
    _end = last == null
        ? const TimeOfDay(hour: 21, minute: 0)
        : TimeOfDay.fromDateTime(last.endsAt);
  }

  @override
  void dispose() {
    _job.dispose();
    _rate.dispose();
    super.dispose();
  }

  int get _startMinute => _start.hour * 60 + _start.minute;

  int get _duration =>
      shiftDurationMinutes(_startMinute, _end.hour * 60 + _end.minute);

  /// The shifts the form describes right now.
  List<Shift> _draft() {
    final double? rate = double.tryParse(_rate.text.trim());
    final Shift? editing = widget.editing;
    if (editing != null) {
      return <Shift>[
        Shift(
          id: editing.id,
          job: _job.text.trim(),
          startsAt: DateTime(
            _day.year,
            _day.month,
            _day.day,
            _start.hour,
            _start.minute,
          ),
          durationMinutes: _duration,
          breakMinutes: editing.breakMinutes,
          hourlyRateCents: rate == null || rate < 0 ? 0 : (rate * 100).round(),
          paid: editing.paid,
          seriesId: editing.seriesId,
        ),
      ];
    }
    return buildShiftSeries(
      job: _job.text.trim(),
      weekdays: _repeats ? _weekdays : <int>{_day.weekday},
      startMinute: _startMinute,
      durationMinutes: _duration,
      breakMinutes: 0,
      hourlyRateCents: rate == null || rate < 0 ? 0 : (rate * 100).round(),
      from: _day,
      until: _repeats ? _until : _day,
    );
  }

  /// Names what the shifts run into, exams first; null when nothing.
  String? _overlapText(List<Shift> shifts) {
    final Map<int, (CalendarEvent, DateTime)> hits =
        <int, (CalendarEvent, DateTime)>{};
    for (final Shift shift in shifts) {
      for (final CalendarEvent event in eventsOverlapping(
        start: shift.startsAt,
        durationMinutes: shift.durationMinutes,
        events: widget.events,
      )) {
        hits.putIfAbsent(event.id, () => (event, shift.startsAt));
      }
    }
    if (hits.isEmpty) return null;
    final List<(CalendarEvent, DateTime)> ordered = hits.values.toList()
      ..sort((a, b) => (a.$1.isExam ? 0 : 1).compareTo(b.$1.isExam ? 0 : 1));
    final CalendarEvent first = ordered.first.$1;
    final DateTime firstDay = ordered.first.$2;
    final String more = ordered.length == 1
        ? ''
        : ' and ${ordered.length - 1} more';
    return 'Overlaps ${first.title} on '
        '${DateFormat('EEE, MMM d').format(firstDay)}$more.';
  }

  void _save() {
    final bool formOk = _formKey.currentState!.validate();
    final bool daysOk = !_repeats || _weekdays.isNotEmpty;
    setState(() => _showDayError = !daysOk);
    if (!formOk || !daysOk) return;
    Navigator.pop(context, (shifts: _draft(), delete: false, andLater: false));
  }

  Future<void> _delete() async {
    final Shift? shift = widget.editing;
    if (shift == null) return;
    final String when =
        '${shift.job}, ${DateFormat('EEE, MMM d').format(shift.startsAt)}';
    if (shift.paid) {
      final bool ok = await confirmDestructive(
        context,
        title: 'Remove a paid shift?',
        message:
            '$when was already paid. Your income stays as it is; '
            'only the shift is removed.',
        confirmLabel: 'Remove',
      );
      if (!ok || !mounted) return;
      Navigator.pop(context, (shifts: null, delete: true, andLater: false));
      return;
    }
    final bool inSeries = shift.seriesId != null;
    final bool? andLater = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Remove this shift?'),
        content: Text(when),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (inSeries)
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('This and later'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.colors.error,
              foregroundColor: ctx.colors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(inSeries ? 'Only this' : 'Remove'),
          ),
        ],
      ),
    );
    if (andLater == null || !mounted) return;
    Navigator.pop(context, (shifts: null, delete: true, andLater: andLater));
  }

  Future<void> _pickTime({required bool start}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      helpText: start ? 'Shift starts' : 'Shift ends',
      initialTime: start ? _start : _end,
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: AppRadius.medium,
    );
    final DateFormat dayFormat = DateFormat('EEE, MMM d');
    final String? overlap = _overlapText(_draft());

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
                widget.editing == null ? 'Add a shift' : 'Edit shift',
                style: textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _job,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Workplace',
                  border: border,
                ),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Workplace required'
                    : null,
              ),
              AppSpacing.gapMd,
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(start: true),
                      child: Text('Starts ${_start.format(context)}'),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(start: false),
                      child: Text('Ends ${_end.format(context)}'),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapXs,
              Text(
                '${formatHours(_duration)} hrs'
                '${_end.hour * 60 + _end.minute <= _startMinute ? ', ends the next day' : ''}',
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(
                  labelText: 'Pay per hour (optional)',
                  prefixText: '₱ ',
                  border: border,
                ),
                onChanged: (_) => setState(() {}),
                validator: (String? value) {
                  final String text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final double? rate = double.tryParse(text);
                  return rate == null || rate < 0 ? 'Enter an amount' : null;
                },
              ),
              AppSpacing.gapSm,
              if (widget.editing == null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeats every week'),
                  value: _repeats,
                  onChanged: (bool value) => setState(() {
                    _repeats = value;
                    if (value && _weekdays.isEmpty) _weekdays.add(_day.weekday);
                  }),
                ),
              if (_repeats) ...<Widget>[
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
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                AppSpacing.gapSm,
              ],
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  _repeats
                      ? 'From ${dayFormat.format(_day)} until ${dayFormat.format(_until)}'
                      : dayFormat.format(_day),
                ),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    helpText: _repeats ? 'Last week it repeats' : 'Shift day',
                    initialDate: _repeats ? _until : _day,
                    firstDate: _repeats
                        ? _day
                        : DateTime(_day.year - 1, _day.month, _day.day),
                    lastDate: DateTime(_day.year + 1, _day.month, _day.day),
                  );
                  if (picked == null) return;
                  setState(() {
                    if (_repeats) {
                      _until = picked;
                    } else {
                      _day = picked;
                      _until = DateTime(
                        picked.year,
                        picked.month,
                        picked.day + 27,
                      );
                    }
                  });
                },
              ),
              AppSpacing.gapLg,
              if (overlap != null) ...<Widget>[
                Text(
                  overlap,
                  style: textStyles.bodySmall?.copyWith(color: colors.error),
                ),
                AppSpacing.gapSm,
              ],
              SizedBox(
                height: AppSizes.buttonHeight,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    overlap != null
                        ? 'Save anyway'
                        : widget.editing == null
                        ? 'Save shift'
                        : 'Save changes',
                  ),
                ),
              ),
              if (widget.editing != null) ...<Widget>[
                AppSpacing.gapSm,
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                    minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete shift'),
                  onPressed: _delete,
                ),
              ],
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}
