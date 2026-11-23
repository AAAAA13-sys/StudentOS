import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../phone/phone_day.dart' show formatDuration;
import '../phone/phone_controller.dart';
import '../phone/phone_screen.dart';
import '../calendar/calendar_controller.dart';
import '../calendar/event.dart';
import 'alarm.dart';
import 'alarm_editor_sheet.dart';
import 'focus_controller.dart';
import 'focus_plan.dart';
import 'focus_platform.dart';
import 'focus_settings_sheet.dart';
import 'wake_plan.dart';
import '../../core/widgets/ponpon.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// The three views of the Calendar tab: the schedule, wake-up alarms and the
/// focus timer.
enum CalendarView { schedule, alarm, focus }

/// Which view of the Calendar tab is showing; other screens can switch it
/// (e.g. the focus banner opens the timer).
final NotifierProvider<CalendarViewController, CalendarView>
calendarViewProvider = NotifierProvider<CalendarViewController, CalendarView>(
  CalendarViewController.new,
);

class CalendarViewController extends Notifier<CalendarView> {
  @override
  CalendarView build() => CalendarView.schedule;

  void show(CalendarView view) => state = view;
}

// Alarms.

/// Wake-up alarms, with the night's phone rest.
class AlarmsPanel extends ConsumerWidget {
  const AlarmsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Alarm>> alarms = ref.watch(alarmControllerProvider);
    final PhoneReadiness? ready = ref.watch(readinessProvider).value;
    // Keeps "Rings in ..." current.
    ref.watch(minutesProvider);

    return alarms.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object _, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text("Couldn't load your alarms."),
            AppSpacing.gapMd,
            FilledButton(
              onPressed: () =>
                  ref.read(alarmControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (List<Alarm> list) => ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 96),
        children: <Widget>[
          if (_gapFor(ref, list) case final AlarmGap gap) ...<Widget>[
            _NoAlarmCard(gap: gap),
            AppSpacing.gapMd,
          ],
          if (ready != null && !ready.alarmsReady) ...<Widget>[
            _ReadinessCard(ready: ready),
            AppSpacing.gapMd,
          ],
          if (list.isEmpty)
            const _EmptyAlarms()
          else
            for (final Alarm a in list) ...<Widget>[
              _AlarmCard(alarm: a),
              AppSpacing.gapSm,
            ],
          // Tonight's phone rest and when to put the phone down.
          AppSpacing.gapMd,
          const PhoneCards(rest: true, usage: false),
        ],
      ),
    );
  }
}

/// The first event a missing alarm leaves the owner oversleeping, if any.
AlarmGap? _gapFor(WidgetRef ref, List<Alarm> alarms) => alarmGapFor(
  events:
      ref.watch(calendarControllerProvider).value ?? const <CalendarEvent>[],
  alarms: alarms,
  now: DateTime.now(),
);

/// "No alarm before Physics 101 at 8:00 AM", with a way to add one.
class _NoAlarmCard extends StatelessWidget {
  const _NoAlarmCard({required this.gap});

  final AlarmGap gap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme text = context.textStyles;
    final String at = DateFormat('h:mm a').format(gap.start);
    return Card(
      margin: EdgeInsets.zero,
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(Icons.alarm_off_rounded, color: colors.onErrorContainer),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'No alarm before ${gap.event.title} at $at',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onErrorContainer,
                    ),
                  ),
                  Text(
                    gap.isToday ? 'Today' : 'Tomorrow',
                    style: text.bodySmall?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            FilledButton.tonal(
              onPressed: () =>
                  showAlarmEditor(context, alarm: suggestedAlarm(gap)),
              child: const Text('Add alarm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAlarms extends StatelessWidget {
  const _EmptyAlarms();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxxl),
      child: Column(
        children: <Widget>[
          const Ponpon(mood: PonponMood.sleepy, size: 120),
          AppSpacing.gapMd,
          Text(
            'No alarms yet',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            'Make one that will not let you sleep through it: maths to turn '
            'it off, a locked volume, and a check that you stayed up.',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard({required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = context.textStyles;
    final ColorScheme colors = context.colors;
    final DateTime now = DateTime.now();
    final DateTime? next = alarm.nextRing(now);
    final Map<int, DateTime>? snoozes = ref.watch(alarmSnoozesProvider).value;
    final DateTime? snoozedUntil = (alarm.enabled && snoozes != null)
        ? snoozes[alarm.id]
        : null;
    final bool snoozed = snoozedUntil != null && snoozedUntil.isAfter(now);
    final Color dim = alarm.enabled
        ? colors.onSurface
        : colors.onSurfaceVariant.withValues(alpha: 0.6);
    final List<String> details = <String>[
      alarm.daysLabel,
      alarm.challengeSummary,
      if (alarm.snoozeLimit == 0) 'no snooze',
      if (alarm.wakeCheck) 'wake-up check',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: () => showAlarmEditor(context, alarm: alarm),
        onLongPress: () async {
          final bool ok = await confirmDestructive(
            context,
            title: 'Delete this alarm?',
            message: 'It will not ring again.',
            confirmLabel: 'Delete',
          );
          if (ok) {
            await ref.read(alarmControllerProvider.notifier).delete(alarm);
          }
        },
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      TimeOfDay(
                        hour: alarm.hour,
                        minute: alarm.minute,
                      ).format(context),
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: _tabular,
                        color: dim,
                      ),
                    ),
                    if (alarm.label.isNotEmpty)
                      Text(
                        alarm.label,
                        style: text.titleSmall?.copyWith(color: dim),
                      ),
                    Text(
                      details.join(' · '),
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (snoozed)
                      Text(
                        'Snoozed until ${TimeOfDay.fromDateTime(snoozedUntil).format(context)}',
                        style: text.bodySmall?.copyWith(
                          color: colors.primary,
                          fontFeatures: _tabular,
                        ),
                      )
                    else if (next != null)
                      Text(
                        'Rings ${ringsIn(next.difference(now))}',
                        style: text.bodySmall?.copyWith(
                          color: colors.primary,
                          fontFeatures: _tabular,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: alarm.enabled,
                onChanged: (bool on) => ref
                    .read(alarmControllerProvider.notifier)
                    .setEnabled(alarm, on),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lists the phone settings that would stop an alarm from ringing.
class _ReadinessCard extends ConsumerWidget {
  const _ReadinessCard({required this.ready});

  final PhoneReadiness ready;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final List<(String, String, String)> missing = <(String, String, String)>[
      if (!ready.notifications)
        ('notifications', 'Notifications', 'Needed to ring at all'),
      if (!ready.exactAlarms)
        ('exactAlarms', 'Alarms & reminders', 'Rings on the minute'),
      if (!ready.fullScreen)
        ('fullScreen', 'Full-screen alerts', 'Shows over the lock screen'),
      if (!ready.batteryUnrestricted)
        (
          'batteryUnrestricted',
          'Battery: unrestricted',
          'Stops Android from putting it to sleep',
        ),
    ];
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: AppRadius.large,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your alarms might not ring',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onErrorContainer,
            ),
          ),
          AppSpacing.gapXs,
          for (final (String key, String title, String why) in missing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                title,
                style: TextStyle(color: colors.onErrorContainer),
              ),
              subtitle: Text(
                why,
                style: TextStyle(color: colors.onErrorContainer),
              ),
              trailing: TextButton(
                onPressed: () =>
                    ref.read(focusPlatformProvider).openSetting(key),
                child: const Text('Turn on'),
              ),
            ),
        ],
      ),
    );
  }
}

// Timer.

/// The focus timer, with screen time.
class FocusPanel extends ConsumerWidget {
  const FocusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FocusState> focus = ref.watch(focusControllerProvider);
    return focus.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object _, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text("Couldn't load the timer."),
            AppSpacing.gapMd,
            FilledButton(
              onPressed: () => ref.invalidate(focusControllerProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (FocusState state) => state.session == null
          ? _TimerIdle(state: state)
          : _TimerRunning(session: state.session!),
    );
  }
}

class _TimerIdle extends ConsumerWidget {
  const _TimerIdle({required this.state});

  final FocusState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FocusSettings s = state.settings;
    final TextTheme text = context.textStyles;
    final ColorScheme colors = context.colors;
    final PhoneReadiness? ready = ref.watch(readinessProvider).value;
    final bool needsService =
        s.lockdown == Lockdown.strict && ready != null && !ready.accessibility;
    final Duration total = s.sequence.fold(
      Duration.zero,
      (Duration sum, (PhaseKind, Duration) p) => sum + p.$2,
    );

    final PhoneState? phone = ref.watch(phoneControllerProvider).value;
    final String? screenOn = phone == null ? null : screenOnToday(phone);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.large,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.rounds == 1 ? 'One block' : '${s.rounds} rounds',
                          style: text.labelLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${s.focusMinutes} min focus',
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: _tabular,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          <String>[
                            if (s.rounds > 1 && s.shortBreakMinutes > 0)
                              '${s.shortBreakMinutes} min breaks',
                            if (s.rounds > s.longBreakEvery &&
                                s.longBreakMinutes > 0)
                              '${s.longBreakMinutes} min long break every '
                                  '${s.longBreakEvery}',
                            'about ${formatDuration(total)} in all',
                          ].join(' · '),
                          style: text.bodySmall?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontFeatures: _tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapSm,
                  const Ponpon(mood: PonponMood.focused, size: 56),
                ],
              ),
              InkWell(
                borderRadius: AppRadius.small,
                onTap: () => showFocusSettings(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minTouchTarget,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        s.lockdown == Lockdown.off
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        size: AppSizes.iconSm,
                        color: colors.onPrimaryContainer,
                      ),
                      AppSpacing.gapSm,
                      Text(
                        'Lockdown: ${s.lockdown.label} · ',
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Change',
                        style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (needsService) ...<Widget>[AppSpacing.gapMd, _AccessibilityCard()],
        AppSpacing.gapMd,
        SizedBox(
          height: AppSizes.buttonHeight,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start focusing'),
            onPressed: needsService
                ? null
                : () => ref.read(focusControllerProvider.notifier).start(),
          ),
        ),
        AppSpacing.gapMd,
        // Today in one card: the fix next to the problem.
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Focused ${formatDuration(Duration(milliseconds: state.todayFocusMs))}'
                  ' · ${state.todayRounds} '
                  '${state.todayRounds == 1 ? 'round' : 'rounds'}',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: _tabular,
                  ),
                ),
                if (screenOn != null) ...<Widget>[
                  AppSpacing.gapXs,
                  Text(
                    screenOn,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        AppSpacing.gapSm,
        const PhoneCards(rest: false, usage: true, compact: true),
      ],
    );
  }
}

class _AccessibilityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: AppRadius.large,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Strict lockdown needs one switch',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapXs,
          const Text(
            'In Accessibility, open "StudentOS strict focus" and turn it on. '
            'It only sees which app opens, never the screen. If Android says '
            'the setting is restricted, open App info for StudentOS, tap ⋮ and '
            'choose "Allow restricted settings" first.',
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              FilledButton.tonal(
                onPressed: () => ref
                    .read(focusPlatformProvider)
                    .openSetting('accessibility'),
                child: const Text('Open Accessibility'),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(focusPlatformProvider).openSetting('appInfo'),
                child: const Text('App info'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerRunning extends ConsumerStatefulWidget {
  const _TimerRunning({required this.session});

  final FocusSession session;

  @override
  ConsumerState<_TimerRunning> createState() => _TimerRunningState();
}

class _TimerRunningState extends ConsumerState<_TimerRunning> {
  /// Strict lockdown asks for the exit sentence before pausing or stopping
  /// during a focus phase.
  Future<bool> _allowedOut(FocusSession session) async {
    if (!(session.settings.lockdown == Lockdown.strict &&
        session.lockedAt(DateTime.now()))) {
      return true;
    }
    return await showExitPhraseDialog(context, session.settings.exitPhrase);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = ref.watch(secondsProvider).value ?? DateTime.now();
    final FocusController controller = ref.read(
      focusControllerProvider.notifier,
    );

    final FocusSession s = widget.session;
    final FocusPhase? phase = s.phaseAt(now);
    final TextTheme text = context.textStyles;
    final ColorScheme colors = context.colors;
    if (phase == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final double done =
        1 -
        s.remaining(now).inMilliseconds /
            (phase.length.inMilliseconds == 0
                ? 1
                : phase.length.inMilliseconds);
    final bool onBreak = phase.kind.isBreak;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Center(
          child: Text(
            '${phase.kind.label} · round ${phase.round} of ${s.totalRounds}',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onBreak ? colors.tertiary : colors.primary,
            ),
          ),
        ),
        AppSpacing.gapXl,
        Center(
          child: SizedBox.square(
            dimension: 240,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CircularProgressIndicator(
                  value: done.clamp(0, 1),
                  strokeWidth: 8,
                  backgroundColor: colors.primaryContainer,
                  color: onBreak ? colors.tertiary : colors.primary,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        clock(s.remaining(now)),
                        style: text.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: _tabular,
                        ),
                      ),
                      if (s.paused)
                        Text('Paused', style: text.labelLarge)
                      else if (s.lockedAt(now))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            AppSpacing.gapXs,
                            Text(
                              '${s.settings.lockdown.label} lockdown',
                              style: text.labelLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapLg,
        Center(
          child: Ponpon(
            mood: s.paused
                ? PonponMood.smug
                : onBreak
                ? PonponMood.sleepy
                : PonponMood.focused,
            size: 88,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          onBreak
              ? 'Step away from the screen. The next round starts on its own.'
              : 'One thing at a time. Your phone will tell you when to rest.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        AppSpacing.gapXl,
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(
                  s.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(s.paused ? 'Resume' : 'Pause'),
                onPressed: () async {
                  if (s.paused) return controller.resume();
                  if (await _allowedOut(s)) await controller.pause();
                },
              ),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(onBreak ? 'Skip break' : 'Skip'),
                onPressed: () async {
                  if (await _allowedOut(s)) await controller.skip();
                },
              ),
            ),
          ],
        ),
        AppSpacing.gapSm,
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colors.error),
          onPressed: () async {
            if (await _allowedOut(s)) await controller.stop();
          },
          child: const Text('Stop session'),
        ),
      ],
    );
  }
}

/// Asks for the exit sentence, typed exactly. True when it matches.
Future<bool> showExitPhraseDialog(BuildContext context, String phrase) async {
  final TextEditingController input = TextEditingController();
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => StatefulBuilder(
      builder: (BuildContext ctx, StateSetter setState) => AlertDialog(
        title: const Text('Leave focus early?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Type this exactly:'),
            AppSpacing.gapXs,
            Text(
              '"$phrase"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapMd,
            TextField(
              controller: input,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep focusing'),
          ),
          FilledButton(
            onPressed: input.text.trim() == phrase
                ? () => Navigator.pop(ctx, true)
                : null,
            child: const Text('Leave'),
          ),
        ],
      ),
    ),
  );
  input.dispose();
  return ok ?? false;
}
