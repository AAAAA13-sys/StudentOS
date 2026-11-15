import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'calendar_controller.dart';
import '../notes/note.dart';
import '../notes/note_editor_sheet.dart';
import '../notes/notes_controller.dart';
import '../notes/notes_repository.dart';
import 'event.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _viewMonth;
  bool _filterByDay = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewMonth = DateTime(now.year, now.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isEventOnDate(CalendarEvent event, DateTime date) {
    final DateTime start = event.startsAt.toLocal();
    final DateTime startDate = DateTime(start.year, start.month, start.day);
    final DateTime targetDate = DateTime(date.year, date.month, date.day);

    if (_isSameDay(startDate, targetDate)) return true;
    if (targetDate.isBefore(startDate)) return false;

    if (event.recurrence == 'daily') return true;
    if (event.recurrence == 'weekly' && start.weekday == date.weekday) return true;
    if (event.recurrence == 'monthly' && start.day == date.day) return true;

    return false;
  }

  List<CalendarEvent> _eventsForDate(List<CalendarEvent> allEvents, DateTime date) {
    return allEvents.where((CalendarEvent e) => _isEventOnDate(e, date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CalendarEvent>> eventsState =
        ref.watch(calendarControllerProvider);
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final DateTime today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open Menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(_viewMonth),
          style: textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous Month',
            onPressed: () {
              setState(() {
                _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Jump to Today',
            onPressed: () {
              setState(() {
                final DateTime now = DateTime.now();
                _selectedDate = DateTime(now.year, now.month, now.day);
                _viewMonth = DateTime(now.year, now.month, 1);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next Month',
            onPressed: () {
              setState(() {
                _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
              });
            },
          ),
        ],
      ),
      body: eventsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
              AppSpacing.gapMd,
              Text('Failed to load events: $err'),
              AppSpacing.gapLg,
              FilledButton(
                onPressed: () =>
                    ref.read(calendarControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (List<CalendarEvent> allEvents) {
          final List<CalendarEvent> dayEvents =
              _eventsForDate(allEvents, _selectedDate)
                ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

          final List<CalendarEvent> displayedEvents = _filterByDay
              ? dayEvents
              : (List<CalendarEvent>.from(allEvents)
                ..sort((a, b) => a.startsAt.compareTo(b.startsAt)));

          return Column(
            children: <Widget>[
              // Interactive Digital Month Calendar Card
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Card(
                  elevation: 0,
                  color: colors.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.large,
                    side: BorderSide(color: colors.outlineVariant, width: 1.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Weekday labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const <Widget>[
                            _WeekdayHeader('S'),
                            _WeekdayHeader('M'),
                            _WeekdayHeader('T'),
                            _WeekdayHeader('W'),
                            _WeekdayHeader('T'),
                            _WeekdayHeader('F'),
                            _WeekdayHeader('S'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Divider(height: 1),
                        const SizedBox(height: 6),
                        // Days grid
                        _buildMonthGrid(allEvents, today, colors, textStyles),
                      ],
                    ),
                  ),
                ),
              ),

              // Agenda Section Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _filterByDay
                            ? DateFormat('EEEE, MMM d').format(_selectedDate)
                            : 'All Events (${displayedEvents.length})',
                        style: textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        FilterChip(
                          label: Text(_filterByDay ? 'Day View' : 'All Events'),
                          selected: _filterByDay,
                          visualDensity: VisualDensity.compact,
                          onSelected: (bool selected) {
                            setState(() {
                              _filterByDay = !selected ? false : true;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: 'Add event for this day',
                          onPressed: () => _showAddEventDialog(
                            context,
                            prefilledDate: _selectedDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Events List
              Expanded(
                child: displayedEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.event_available_outlined,
                              size: 48,
                              color: colors.outlineVariant,
                            ),
                            AppSpacing.gapMd,
                            Text(
                              _filterByDay
                                  ? 'No events on ${DateFormat('MMM d').format(_selectedDate)}'
                                  : 'No events scheduled',
                              style: textStyles.titleMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.gapSm,
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.add_rounded),
                              label: Text('Add Event for ${DateFormat('MMM d').format(_selectedDate)}'),
                              onPressed: () => _showAddEventDialog(
                                context,
                                prefilledDate: _selectedDate,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(calendarControllerProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: displayedEvents.length,
                          separatorBuilder: (_, _) => AppSpacing.gapMd,
                          itemBuilder: (BuildContext context, int index) {
                            final CalendarEvent event = displayedEvents[index];
                            final DateTime localStart = event.startsAt.toLocal();

                            return Card(
                              elevation: 0,
                              color: colors.surfaceContainerLowest,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.large,
                                side: BorderSide(
                                  color: colors.outlineVariant,
                                  width: 1.0,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: AppRadius.large,
                                onTap: () => _showAddEventDialog(
                                  context,
                                  existingEvent: event,
                                ),
                                child: Padding(
                                  padding: AppSpacing.card,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          // Lavender Date Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.primaryContainer,
                                              borderRadius: AppRadius.small,
                                            ),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  DateFormat('MMM').format(localStart).toUpperCase(),
                                                  style: textStyles.labelSmall?.copyWith(
                                                    color: colors.onPrimaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat('d').format(localStart),
                                                  style: textStyles.titleMedium?.copyWith(
                                                    color: colors.onPrimaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AppSpacing.gapMd,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  event.title,
                                                  style: textStyles.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                AppSpacing.gapXs,
                                                Row(
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.access_time_rounded,
                                                      size: 15,
                                                      color: colors.onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${DateFormat('h:mm a').format(localStart)} (${event.durationMinutes}m)',
                                                      style: textStyles.bodySmall?.copyWith(
                                                        color: colors.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (event.location != null &&
                                                    event.location!.isNotEmpty) ...<Widget>[
                                                  AppSpacing.gapXs,
                                                  Row(
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons.location_on_outlined,
                                                        size: 15,
                                                        color: colors.onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          event.location!,
                                                          style: textStyles.bodySmall?.copyWith(
                                                            color: colors.onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: colors.error,
                                            ),
                                            tooltip: 'Delete Event',
                                            onPressed: () =>
                                                _confirmDelete(context, event.id),
                                          ),
                                        ],
                                      ),
                                      if (event.recurrence != 'none') ...<Widget>[
                                        AppSpacing.gapSm,
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.surfaceContainerLow,
                                            borderRadius: AppRadius.pill,
                                            border: Border.all(
                                              color: colors.outlineVariant,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(
                                                Icons.repeat_rounded,
                                                size: 13,
                                                color: colors.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Repeats ${event.recurrence}',
                                                style: textStyles.labelSmall?.copyWith(
                                                  color: colors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: () => _openNote(event),
                                          icon: const Icon(
                                            Icons.article_outlined,
                                            size: 18,
                                          ),
                                          label: Text(
                                            event.noteId != null
                                                ? 'Open note'
                                                : 'Add note',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Event',
        onPressed: () => _showAddEventDialog(
          context,
          prefilledDate: _selectedDate,
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  /// Opens the note attached to [event], creating and attaching one titled
  /// after the event when there is none (or it was deleted).
  Future<void> _openNote(CalendarEvent event) async {
    final NotesRepository notes = ref.read(notesRepositoryProvider);
    Note? note = event.noteId == null
        ? null
        : await notes.getNote(event.noteId!);
    if (note == null) {
      final int noteId = await notes.createNote(
        Note(id: 0, title: event.title, body: '', tags: const <String>[]),
      );
      await ref
          .read(calendarControllerProvider.notifier)
          .updateEvent(event.withIds(id: event.id, noteId: noteId));
      ref.invalidate(notesControllerProvider);
      note = await notes.getNote(noteId);
    }
    if (note == null || !mounted) return;
    await showNoteEditor(context, ref, note);
  }

  /// Builds the 7-column interactive digital month calendar grid.
  Widget _buildMonthGrid(
    List<CalendarEvent> allEvents,
    DateTime today,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final DateTime firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final int daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final int startingDayOfWeek = firstDayOfMonth.weekday % 7; // Sunday = 0
    final int totalCells = ((startingDayOfWeek + daysInMonth + 6) ~/ 7) * 7;
    final int rowCount = totalCells ~/ 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(rowCount, (int rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(7, (int colIndex) {
              final int cellIndex = rowIndex * 7 + colIndex;
              final int dayOffset = cellIndex - startingDayOfWeek + 1;
              final DateTime cellDate =
                  DateTime(_viewMonth.year, _viewMonth.month, dayOffset);
              final bool isCurrentMonth = cellDate.month == _viewMonth.month;
              final bool isSelected = _isSameDay(cellDate, _selectedDate);
              final bool isToday = _isSameDay(cellDate, today);
              final bool hasEvents = _eventsForDate(allEvents, cellDate).isNotEmpty;

              return SizedBox(
                width: 38,
                height: 34,
                child: InkWell(
                  borderRadius: AppRadius.pill,
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                      _filterByDay = true;
                      if (!isCurrentMonth) {
                        _viewMonth = DateTime(cellDate.year, cellDate.month, 1);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colors.primary
                          : (isToday
                              ? colors.primaryContainer.withValues(alpha: 0.5)
                              : Colors.transparent),
                      border: isToday && !isSelected
                          ? Border.all(color: colors.primary, width: 1.5)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Text(
                          '${cellDate.day}',
                          style: textStyles.bodySmall?.copyWith(
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : (isCurrentMonth ? FontWeight.w600 : FontWeight.w400),
                            color: isSelected
                                ? colors.onPrimary
                                : (isCurrentMonth
                                    ? (isToday ? colors.primary : colors.onSurface)
                                    : colors.outlineVariant),
                          ),
                        ),
                        if (hasEvents)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? colors.onPrimary
                                    : colors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(calendarControllerProvider.notifier).deleteEvent(id);
    }
  }

  Future<void> _showAddEventDialog(
    BuildContext context, {
    DateTime? prefilledDate,
    CalendarEvent? existingEvent,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController titleController =
        TextEditingController(text: existingEvent?.title ?? '');
    final TextEditingController locationController =
        TextEditingController(text: existingEvent?.location ?? '');
    final TextEditingController notesController =
        TextEditingController(text: existingEvent?.notes ?? '');

    final DateTime baseDate = existingEvent?.startsAt.toLocal() ??
        prefilledDate ??
        _selectedDate;

    DateTime eventDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    TimeOfDay eventTime = existingEvent != null
        ? TimeOfDay.fromDateTime(existingEvent.startsAt.toLocal())
        : TimeOfDay.now();

    int durationMinutes = existingEvent?.durationMinutes ?? 60;
    String recurrence = existingEvent?.recurrence ?? 'none';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.sm,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            existingEvent != null ? 'Edit Event' : 'New Event',
                            style: ctx.textStyles.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ctx.colors.primaryContainer,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              DateFormat('MMM d, yyyy').format(eventDate),
                              style: ctx.textStyles.labelSmall?.copyWith(
                                color: ctx.colors.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapLg,
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Physics Lecture, Math Quiz',
                          border: OutlineInputBorder(borderRadius: AppRadius.medium),
                        ),
                        validator: (String? val) =>
                            val == null || val.trim().isEmpty ? 'Title required' : null,
                      ),
                      AppSpacing.gapMd,
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: eventDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => eventDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_rounded, size: 18),
                              label: Text(DateFormat('MMM d, yyyy').format(eventDate)),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: eventTime,
                                );
                                if (picked != null) {
                                  setModalState(() => eventTime = picked);
                                }
                              },
                              icon: const Icon(Icons.access_time_rounded, size: 18),
                              label: Text(eventTime.format(ctx)),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: durationMinutes,
                              decoration: const InputDecoration(
                                labelText: 'Duration',
                                border: OutlineInputBorder(borderRadius: AppRadius.medium),
                              ),
                              items: const <DropdownMenuItem<int>>[
                                DropdownMenuItem<int>(value: 30, child: Text('30 mins')),
                                DropdownMenuItem<int>(value: 45, child: Text('45 mins')),
                                DropdownMenuItem<int>(value: 60, child: Text('1 hour')),
                                DropdownMenuItem<int>(value: 90, child: Text('1.5 hours')),
                                DropdownMenuItem<int>(value: 120, child: Text('2 hours')),
                              ],
                              onChanged: (int? val) {
                                if (val != null) setModalState(() => durationMinutes = val);
                              },
                            ),
                          ),
                          AppSpacing.gapSm,
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: recurrence,
                              decoration: const InputDecoration(
                                labelText: 'Repeat',
                                border: OutlineInputBorder(borderRadius: AppRadius.medium),
                              ),
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(value: 'none', child: Text('Does not repeat')),
                                DropdownMenuItem<String>(value: 'daily', child: Text('Daily')),
                                DropdownMenuItem<String>(value: 'weekly', child: Text('Weekly')),
                                DropdownMenuItem<String>(value: 'monthly', child: Text('Monthly')),
                              ],
                              onChanged: (String? val) {
                                if (val != null) setModalState(() => recurrence = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location (optional)',
                          hintText: 'e.g. Room 304, Science Lab',
                          border: OutlineInputBorder(borderRadius: AppRadius.medium),
                        ),
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'e.g. Bring lab coat and calculator',
                          border: OutlineInputBorder(borderRadius: AppRadius.medium),
                        ),
                      ),
                      AppSpacing.gapXl,
                      SizedBox(
                        height: AppSizes.buttonHeight,
                        child: FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final DateTime combinedStart = DateTime(
                              eventDate.year,
                              eventDate.month,
                              eventDate.day,
                              eventTime.hour,
                              eventTime.minute,
                            );

                            final CalendarEvent newEvent = CalendarEvent(
                              id: existingEvent?.id ?? 0,
                              title: titleController.text.trim(),
                              startsAt: combinedStart,
                              durationMinutes: durationMinutes,
                              location: locationController.text.trim().isNotEmpty
                                  ? locationController.text.trim()
                                  : null,
                              notes: notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim()
                                  : null,
                              recurrence: recurrence,
                              recurrenceUntil: existingEvent?.recurrenceUntil,
                              reminderMinutes: existingEvent?.reminderMinutes,
                              noteId: existingEvent?.noteId,
                            );

                            if (existingEvent != null) {
                              ref
                                  .read(calendarControllerProvider.notifier)
                                  .updateEvent(newEvent);
                            } else {
                              ref.read(calendarControllerProvider.notifier).addEvent(newEvent);
                            }

                            Navigator.pop(ctx);
                          },
                          child: Text(existingEvent != null ? 'Update Event' : 'Save Event'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Center(
        child: Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
