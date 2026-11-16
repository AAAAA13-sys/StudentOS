import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/month_switcher.dart';
import 'calendar_controller.dart';
import 'class_schedule_sheet.dart';
import '../notes/note.dart';
import '../notes/note_editor_sheet.dart';
import '../notes/notes_controller.dart';
import '../notes/notes_repository.dart';
import 'event.dart';
import '../work/add_shift_sheet.dart';
import '../work/day_shifts.dart';
import '../work/shift.dart';
import '../work/work_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _viewMonth;
  bool _filterByDay = true;

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

  List<CalendarEvent> _eventsForDate(
    List<CalendarEvent> allEvents,
    DateTime date,
  ) {
    return allEvents.where((CalendarEvent e) => e.occursOn(date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CalendarEvent>> eventsState = ref.watch(
      calendarControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final DateTime today = DateTime.now();
    final Set<DateTime> shiftDays = <DateTime>{
      for (final Shift shift
          in ref.watch(workControllerProvider).value ?? const <Shift>[])
        DateTime(shift.startsAt.year, shift.startsAt.month, shift.startsAt.day),
    };

    return Scaffold(
      appBar: AppTopBar(
        title: 'Calendar',
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Today',
            onPressed: () => _showMonth(DateTime.now()),
          ),
          PopupMenuButton<void>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More',
            itemBuilder: (BuildContext context) => <PopupMenuEntry<void>>[
              PopupMenuItem<void>(
                onTap: _addClass,
                child: const Text('Add a class'),
              ),
              PopupMenuItem<void>(
                onTap: () => addShift(context, ref, day: _selectedDate),
                child: const Text('Add a shift'),
              ),
            ],
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
          final List<CalendarEvent> dayEvents = _eventsForDate(
            allEvents,
            _selectedDate,
          )..sort((a, b) => a.startsAt.compareTo(b.startsAt));

          final List<CalendarEvent> displayedEvents = _filterByDay
              ? dayEvents
              : (List<CalendarEvent>.from(allEvents)
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt)));

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: MonthSwitcher(month: _viewMonth, onChanged: _showMonth),
              ),
              // Interactive Digital Month Calendar Card
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails details) {
                    final double velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 200) return;
                    _showMonth(
                      DateTime(
                        _viewMonth.year,
                        _viewMonth.month + (velocity < 0 ? 1 : -1),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    color: colors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.large,
                      side: BorderSide(
                        color: colors.outlineVariant,
                        width: 1.0,
                      ),
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
                          _buildMonthGrid(
                            allEvents,
                            shiftDays,
                            today,
                            colors,
                            textStyles,
                          ),
                        ],
                      ),
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
                            : 'All events (${displayedEvents.length})',
                        style: textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FilterChip(
                      label: const Text('This day'),
                      selected: _filterByDay,
                      visualDensity: VisualDensity.compact,
                      onSelected: (bool selected) {
                        setState(() => _filterByDay = selected);
                      },
                    ),
                  ],
                ),
              ),

              if (_filterByDay) DayShifts(day: _selectedDate),

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
                                  ? (shiftDays.contains(_selectedDate)
                                        ? 'No other events on ${DateFormat('MMM d').format(_selectedDate)}'
                                        : 'No events on ${DateFormat('MMM d').format(_selectedDate)}')
                                  : 'No events scheduled',
                              style: textStyles.titleMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.gapSm,
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.add_rounded),
                              label: Text(
                                'Add Event for ${DateFormat('MMM d').format(_selectedDate)}',
                              ),
                              onPressed: () => _showAddEventDialog(
                                context,
                                prefilledDate: _selectedDate,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(calendarControllerProvider.notifier)
                            .refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            96,
                          ),
                          itemCount: displayedEvents.length,
                          separatorBuilder: (_, _) => AppSpacing.gapMd,
                          itemBuilder: (BuildContext context, int index) {
                            final CalendarEvent event = displayedEvents[index];
                            final DateTime start = event.startsAt.toLocal();
                            final DateTime localStart = _filterByDay
                                ? DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    start.hour,
                                    start.minute,
                                  )
                                : start;
                            final String? countdown = event.countdownBadge(
                              today,
                            );

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
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.xs,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  DateFormat('MMM')
                                                      .format(localStart)
                                                      .toUpperCase(),
                                                  style: textStyles.labelSmall
                                                      ?.copyWith(
                                                        color: colors
                                                            .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Text(
                                                  DateFormat('d')
                                                      .format(localStart),
                                                  style: textStyles.titleMedium
                                                      ?.copyWith(
                                                        color: colors
                                                            .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AppSpacing.gapMd,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                if (countdown !=
                                                    null) ...<Widget>[
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: event.isExam
                                                          ? colors
                                                                .errorContainer
                                                          : colors
                                                                .primaryContainer,
                                                      borderRadius:
                                                          AppRadius.pill,
                                                      border: Border.all(
                                                        color: event.isExam
                                                            ? colors.error
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  )
                                                            : colors.primary
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                        width: 0.75,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      event.isExam
                                                          ? '🚨 Exam • $countdown'
                                                          : '⚠️ Due • $countdown',
                                                      style: textStyles
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: event.isExam
                                                                ? colors
                                                                      .onErrorContainer
                                                                : colors
                                                                      .onPrimaryContainer,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                                Text(
                                                  event.title,
                                                  style: textStyles.titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                AppSpacing.gapXs,
                                                Row(
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.access_time_rounded,
                                                      size: 15,
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${DateFormat('h:mm a').format(localStart)} (${event.durationMinutes}m)',
                                                      style: textStyles
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: colors
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                if (event.location != null &&
                                                    event
                                                        .location!
                                                        .isNotEmpty) ...<
                                                  Widget
                                                >[
                                                  AppSpacing.gapXs,
                                                  Row(
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        size: 15,
                                                        color: colors
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          event.location!,
                                                          style: textStyles
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color: colors
                                                                    .onSurfaceVariant,
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
                                              size: 20,
                                              color: colors.onSurfaceVariant,
                                            ),
                                            tooltip: 'Delete',
                                            onPressed: () =>
                                                _confirmDelete(event),
                                          ),
                                        ],
                                      ),
                                      if (event
                                          .checklistItems
                                          .isNotEmpty) ...<Widget>[
                                        const SizedBox(height: 6),
                                        for (
                                          int i = 0;
                                          i < event.checklistItems.length;
                                          i++
                                        ) ...<Widget>[
                                          InkWell(
                                            borderRadius: AppRadius.small,
                                            onTap: () async {
                                              final CalendarEvent updated =
                                                  event.toggleChecklistItem(i);
                                              await ref
                                                  .read(
                                                    calendarControllerProvider
                                                        .notifier,
                                                  )
                                                  .updateEvent(updated);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2.5,
                                                  ),
                                              child: Row(
                                                children: <Widget>[
                                                  Icon(
                                                    event.checklistItems[i].done
                                                        ? Icons
                                                              .check_box_rounded
                                                        : Icons
                                                              .check_box_outline_blank_rounded,
                                                    size: 17,
                                                    color:
                                                        event
                                                            .checklistItems[i]
                                                            .done
                                                        ? colors.primary
                                                        : colors
                                                              .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      event
                                                          .checklistItems[i]
                                                          .text,
                                                      style: textStyles.bodySmall?.copyWith(
                                                        decoration:
                                                            event
                                                                .checklistItems[i]
                                                                .done
                                                            ? TextDecoration
                                                                  .lineThrough
                                                            : null,
                                                        color:
                                                            event
                                                                .checklistItems[i]
                                                                .done
                                                            ? colors
                                                                  .onSurfaceVariant
                                                            : colors.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                      ],
                                      Row(
                                        children: <Widget>[
                                          if (event.recurrence != 'none')
                                            Container(
                                              margin: const EdgeInsets.only(
                                                right: AppSpacing.sm,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
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
                                                    style: textStyles.labelSmall
                                                        ?.copyWith(
                                                          color: colors.primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const Spacer(),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
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
                                        ],
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
        onPressed: () =>
            _showAddEventDialog(context, prefilledDate: _selectedDate),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _addClass() async {
    final List<CalendarEvent>? events = await showClassScheduleSheet(context);
    if (events == null || events.isEmpty || !mounted) return;
    await ref.read(calendarControllerProvider.notifier).addEvents(events);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Added ${events.first.title} on ${events.length} '
            '${events.length == 1 ? 'day' : 'days'} a week',
          ),
        ),
      );
  }

  /// Opens the note attached to [event]. When there is none (or it was
  /// deleted) a draft titled after the event opens instead; it is stored and
  /// attached only when saved.
  Future<void> _openNote(CalendarEvent event) async {
    final NotesRepository notes = ref.read(notesRepositoryProvider);
    final Note? note = event.noteId == null
        ? null
        : await notes.getNote(event.noteId!);
    if (!mounted) return;
    if (note != null) {
      await showNoteEditor(context, ref, note);
      return;
    }
    await showNoteEditor(
      context,
      ref,
      Note(id: 0, title: event.title, body: '', tags: const <String>[]),
      onCreate: (Note draft) async {
        final int noteId = await notes.createNote(draft);
        await ref
            .read(calendarControllerProvider.notifier)
            .updateEvent(event.withIds(id: event.id, noteId: noteId));
        ref.invalidate(notesControllerProvider);
      },
    );
  }

  /// Builds the 7-column interactive digital month calendar grid.
  Widget _buildMonthGrid(
    List<CalendarEvent> allEvents,
    Set<DateTime> shiftDays,
    DateTime today,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final DateTime firstDayOfMonth = DateTime(
      _viewMonth.year,
      _viewMonth.month,
      1,
    );
    final int daysInMonth = DateTime(
      _viewMonth.year,
      _viewMonth.month + 1,
      0,
    ).day;
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
              final DateTime cellDate = DateTime(
                _viewMonth.year,
                _viewMonth.month,
                dayOffset,
              );
              final bool isCurrentMonth = cellDate.month == _viewMonth.month;
              final bool isSelected = _isSameDay(cellDate, _selectedDate);
              final bool isToday = _isSameDay(cellDate, today);
              final bool hasEvents = _eventsForDate(
                allEvents,
                cellDate,
              ).isNotEmpty;
              final bool hasShift = shiftDays.contains(
                DateTime(cellDate.year, cellDate.month, cellDate.day),
              );
              final Color markColor = isSelected
                  ? colors.onPrimary
                  : colors.primary;

              return SizedBox(
                width: 40,
                height: 40,
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
                                : (isCurrentMonth
                                      ? FontWeight.w600
                                      : FontWeight.w400),
                            color: isSelected
                                ? colors.onPrimary
                                : (isCurrentMonth
                                      ? (isToday
                                            ? colors.primary
                                            : colors.onSurface)
                                      : colors.outlineVariant),
                          ),
                        ),
                        if (hasEvents || hasShift)
                          // A filled dot for events, a ring for a shift.
                          Positioned(
                            bottom: 2,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (hasEvents)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: markColor,
                                    ),
                                  ),
                                if (hasEvents && hasShift)
                                  const SizedBox(width: 2),
                                if (hasShift)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: markColor,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                              ],
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

  /// Shows [month]; the selected day follows so "add" never targets a day
  /// that is off screen.
  void _showMonth(DateTime month) {
    final DateTime now = DateTime.now();
    setState(() {
      _viewMonth = DateTime(month.year, month.month);
      _selectedDate = month.year == now.year && month.month == now.month
          ? DateTime(now.year, now.month, now.day)
          : _viewMonth;
    });
  }

  Future<void> _confirmDelete(CalendarEvent event) async {
    final bool repeats = event.recurrence != 'none';
    final bool confirmed = await confirmDestructive(
      context,
      title: repeats ? 'Delete every "${event.title}"?' : 'Delete event?',
      message: repeats
          ? 'This repeats ${event.recurrence}. Every occurrence will be '
                'removed, past and future.'
          : '"${event.title}" will be removed.',
    );
    if (confirmed) {
      await ref.read(calendarControllerProvider.notifier).deleteEvent(event.id);
    }
  }

  Future<void> _showAddEventDialog(
    BuildContext context, {
    DateTime? prefilledDate,
    CalendarEvent? existingEvent,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );
    final TextEditingController locationController = TextEditingController(
      text: existingEvent?.location ?? '',
    );
    final TextEditingController notesController = TextEditingController(
      // The type tag line is shown as the chips instead.
      text: CalendarEvent.notesWithType(existingEvent?.notes, 'general') ?? '',
    );
    final FocusNode notesFocus = FocusNode();

    final DateTime baseDate =
        existingEvent?.startsAt.toLocal() ?? prefilledDate ?? _selectedDate;

    DateTime eventDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    TimeOfDay eventTime = existingEvent != null
        ? TimeOfDay.fromDateTime(existingEvent.startsAt.toLocal())
        : TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: 0);

    int durationMinutes = existingEvent?.durationMinutes ?? 60;
    String recurrence = existingEvent?.recurrence ?? 'none';
    String eventType = existingEvent?.isExam == true
        ? 'exam'
        : (existingEvent?.isAssignment == true ? 'assignment' : 'general');

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
                      AppSpacing.gapMd,
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            ChoiceChip(
                              label: const Text('General'),
                              selected: eventType == 'general',
                              onSelected: (_) =>
                                  setModalState(() => eventType = 'general'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Exam / Quiz'),
                              selected: eventType == 'exam',
                              onSelected: (_) =>
                                  setModalState(() => eventType = 'exam'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Assignment'),
                              selected: eventType == 'assignment',
                              onSelected: (_) =>
                                  setModalState(() => eventType = 'assignment'),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapLg,
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Physics Lecture, Math Quiz',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                        validator: (String? val) =>
                            val == null || val.trim().isEmpty
                            ? 'Title required'
                            : null,
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
                              icon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                              ),
                              label: Text(
                                DateFormat('MMM d, yyyy').format(eventDate),
                              ),
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
                              icon: const Icon(
                                Icons.access_time_rounded,
                                size: 18,
                              ),
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
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.medium,
                                ),
                              ),
                              items: const <DropdownMenuItem<int>>[
                                DropdownMenuItem<int>(
                                  value: 30,
                                  child: Text('30 mins'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 45,
                                  child: Text('45 mins'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 60,
                                  child: Text('1 hour'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 90,
                                  child: Text('1.5 hours'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 120,
                                  child: Text('2 hours'),
                                ),
                              ],
                              onChanged: (int? val) {
                                if (val != null) {
                                  setModalState(() => durationMinutes = val);
                                }
                              },
                            ),
                          ),
                          AppSpacing.gapSm,
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: recurrence,
                              decoration: const InputDecoration(
                                labelText: 'Repeat',
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.medium,
                                ),
                              ),
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(
                                  value: 'none',
                                  child: Text('Does not repeat'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'daily',
                                  child: Text('Daily'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'weekly',
                                  child: Text('Weekly'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'monthly',
                                  child: Text('Monthly'),
                                ),
                              ],
                              onChanged: (String? val) {
                                if (val != null) {
                                  setModalState(() => recurrence = val);
                                }
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
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: notesController,
                        focusNode: notesFocus,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes & Checklist (optional)',
                          hintText: 'e.g. - [ ] Bring calculator\n- [ ] Review formula sheet',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            final String current = notesController.text;
                            final String prefix =
                                current.isEmpty || current.endsWith('\n')
                                ? ''
                                : '\n';
                            notesController.text = '$current$prefix- [ ] ';
                            notesController
                                .selection = TextSelection.fromPosition(
                              TextPosition(offset: notesController.text.length),
                            );
                            // So the item's text is typed here, not in
                            // whichever field had the cursor.
                            notesFocus.requestFocus();
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.add_task_rounded, size: 16),
                          label: const Text(
                            'Add checklist item',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      AppSpacing.gapLg,
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

                            final String? combinedNotes =
                                CalendarEvent.notesWithType(
                                  notesController.text,
                                  eventType,
                                );

                            final CalendarEvent newEvent = CalendarEvent(
                              id: existingEvent?.id ?? 0,
                              title: titleController.text.trim(),
                              startsAt: combinedStart,
                              durationMinutes: durationMinutes,
                              location:
                                  locationController.text.trim().isNotEmpty
                                  ? locationController.text.trim()
                                  : null,
                              notes: combinedNotes,
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
                              ref
                                  .read(calendarControllerProvider.notifier)
                                  .addEvent(newEvent);
                            }

                            Navigator.pop(ctx);
                          },
                          child: Text(
                            existingEvent != null
                                ? 'Update Event'
                                : 'Save Event',
                          ),
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
