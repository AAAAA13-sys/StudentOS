import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'calendar_controller.dart';
import 'event.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CalendarEvent>> eventsState =
        ref.watch(calendarControllerProvider);
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(_selectedDate),
          style: textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month - 1,
                  _selectedDate.day,
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + 1,
                  _selectedDate.day,
                );
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
        data: (List<CalendarEvent> events) {
          final List<CalendarEvent> sortedEvents = List<CalendarEvent>.from(events)
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

          if (sortedEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.event_available_outlined,
                    size: 64,
                    color: colors.outlineVariant,
                  ),
                  AppSpacing.gapMd,
                  Text(
                    'No events scheduled',
                    style: textStyles.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Tap + to create your first event',
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(calendarControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: AppSpacing.screen,
              itemCount: sortedEvents.length,
              separatorBuilder: (_, _) => AppSpacing.gapMd,
              itemBuilder: (BuildContext context, int index) {
                final CalendarEvent event = sortedEvents[index];
                final DateTime localStart = event.startsAt.toLocal();

                return Card(
                  elevation: 0,
                  color: colors.surfaceContainerLow,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.large,
                  ),
                  child: Padding(
                    padding: AppSpacing.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AppSpacing.gapXs,
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
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
                                          size: 16,
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
                              icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                              onPressed: () => _confirmDelete(context, event.id),
                            ),
                          ],
                        ),
                        if (event.recurrence != 'none') ...<Widget>[
                          AppSpacing.gapSm,
                          Chip(
                            label: Text(
                              'Repeats ${event.recurrence}',
                              style: textStyles.labelSmall,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
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

  Future<void> _showAddEventDialog(BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime eventDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay eventTime = TimeOfDay.fromDateTime(eventDate);
    int durationMinutes = 60;
    String recurrence = 'none';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xl,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'New Event',
                        style: ctx.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapLg,
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
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
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location (optional)',
                          border: OutlineInputBorder(borderRadius: AppRadius.medium),
                        ),
                      ),
                      AppSpacing.gapMd,
                      DropdownButtonFormField<String>(
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

                            ref.read(calendarControllerProvider.notifier).addEvent(
                                  CalendarEvent(
                                    id: 0,
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
                                  ),
                                );
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save Event'),
                        ),
                      ),
                      AppSpacing.gapLg,
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
