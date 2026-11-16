import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_top_bar.dart';
import 'phone_controller.dart';
import 'phone_day.dart';
import 'phone_usage.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Screen time on its own page (the Clock tab shows [PhoneCards] instead).
class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar(title: 'Screen time'),
      body: PhoneBody(),
    );
  }
}

/// Screen time and phone rest, read from this phone's own usage history.
/// It reports and plans; it never sets limits or judges a day.
class PhoneBody extends ConsumerStatefulWidget {
  const PhoneBody({super.key});

  @override
  ConsumerState<PhoneBody> createState() => _PhoneBodyState();
}

class _PhoneBodyState extends ConsumerState<PhoneBody> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from Settings, or after a while away, reads Android again.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(phoneControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PhoneState> phone = ref.watch(phoneControllerProvider);
    final ColorScheme colors = context.colors;

    return phone.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            AppSpacing.gapMd,
            Text('Could not read phone use: $err'),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: () =>
                  ref.read(phoneControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (PhoneState state) => RefreshIndicator(
        onRefresh: () => ref.read(phoneControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: phoneCards(context, state, rest: true, usage: true),
        ),
      ),
    );
  }
}

/// The screen-time cards for [state]. [rest] is the night's phone rest and
/// plan; [usage] is today, the week and top apps.
List<Widget> phoneCards(
  BuildContext context,
  PhoneState state, {
  required bool rest,
  required bool usage,
}) {
  if (!state.hasAccess) {
    return usage ? <Widget>[const _AccessCard()] : <Widget>[];
  }
  return <Widget>[
    if (usage) ...<Widget>[_TodayCard(state: state), AppSpacing.gapMd],
    if (rest) ...<Widget>[_RestCard(state: state), AppSpacing.gapMd],
    if (usage) ...<Widget>[
      _WeekCard(state: state),
      AppSpacing.gapMd,
      _AppsCard(state: state),
      AppSpacing.gapSm,
      Text(
        'Read from this phone only. Nothing leaves it.',
        textAlign: TextAlign.center,
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  ];
}

/// Screen-time cards to place inside another list (no scrolling of their
/// own). Shows nothing while loading or when Android will not answer.
class PhoneCards extends ConsumerWidget {
  const PhoneCards({required this.rest, required this.usage, super.key});

  final bool rest;
  final bool usage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PhoneState? state = ref.watch(phoneControllerProvider).value;
    if (state == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: phoneCards(context, state, rest: rest, usage: usage),
    );
  }
}

class _AccessCard extends ConsumerWidget {
  const _AccessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textStyles = context.textStyles;
    final ColorScheme colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.phone_android_rounded, color: colors.primary),
            AppSpacing.gapMd,
            Text(
              'See your phone time',
              style: textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapSm,
            const Text(
              'StudentOS can show how long the screen is on, which apps '
              'take the time, and how long the phone rests at night before '
              'your next class or shift. It needs Usage access, which you '
              'turn on in Settings.',
            ),
            AppSpacing.gapSm,
            Text(
              'Everything stays on this phone. If Android says the setting '
              'is restricted, open App info for StudentOS, tap ⋮ and choose '
              '"Allow restricted settings" first.',
              style: textStyles.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapLg,
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: FilledButton(
                onPressed: () => ref
                    .read(phoneControllerProvider.notifier)
                    .openAccessSettings(),
                child: const Text('Open Usage access'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});

  final PhoneState state;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final PhoneDay? day = state.dayFor(today);
    final TextTheme textStyles = context.textStyles;
    final ColorScheme colors = context.colors;
    final String? usual = day == null
        ? null
        : comparedWithUsual(day.screenOnMs, _averageSoFar(state, now));
    final List<String> details = <String>[
      if (day != null)
        '${day.unlocks} ${day.unlocks == 1 ? 'unlock' : 'unlocks'}',
      if (day?.firstPickup != null)
        'first at ${DateFormat('h:mm a').format(day!.firstPickup!)}',
    ];

    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.large,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Screen on today',
            style: textStyles.labelLarge?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            formatDuration(Duration(milliseconds: day?.screenOnMs ?? 0)),
            style: textStyles.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: _tabular,
              color: colors.onPrimaryContainer,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            <String>[...details, ?usual].join(' · '),
            style: textStyles.bodySmall?.copyWith(
              fontFeatures: _tabular,
              color: colors.onPrimaryContainer,
            ),
          ),
          if (!state.androidAnswered) ...<Widget>[
            AppSpacing.gapXs,
            Text(
              'Android did not answer just now; pull down to try again.',
              style: textStyles.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The usual amount by this time of day: the average of complete days,
  /// scaled to the share of the day that has passed, so a morning is not
  /// compared with a whole day.
  static int? _averageSoFar(PhoneState state, DateTime now) {
    final int? average = state.averageMs;
    if (average == null) return null;
    final double share = (now.hour * 60 + now.minute) / (24 * 60);
    // Before 9 AM there is too little of the day to compare.
    if (now.hour < 9) return null;
    return (average * share).round();
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({required this.state});

  final PhoneState state;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final PhoneDay? day = state.dayFor(today);
    final TextTheme textStyles = context.textStyles;
    final ColorScheme colors = context.colors;
    final DateFormat time = DateFormat('h:mm a');
    final Commitment? next = state.commitment;
    final String when = state.nextMorning == today ? 'Today' : 'Tomorrow';

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Phone rest',
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapXs,
            if (day?.rest != null) ...<Widget>[
              Text(
                formatDuration(day!.rest!),
                style: textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: _tabular,
                ),
              ),
              Text(
                'Last night, screen off ${time.format(day.restStart!)} – '
                '${time.format(day.restEnd!)}',
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: _tabular,
                ),
              ),
            ] else
              Text(
                'No long screen-off stretch found last night.',
                style: textStyles.bodyMedium,
              ),
            AppSpacing.gapMd,
            Divider(height: 1, color: colors.outlineVariant),
            AppSpacing.gapMd,
            Text(
              next == null
                  ? '$when has nothing on the calendar.'
                  : '$when starts with ${next.title} at '
                        '${time.format(next.at)}. For '
                        '${plannedRest.inHours} hours of phone rest before it, '
                        'phone down by ${time.format(next.at.subtract(plannedRest))}.',
              style: textStyles.bodyMedium?.copyWith(fontFeatures: _tabular),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends ConsumerWidget {
  const _WeekCard({required this.state});

  final PhoneState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<DateTime> week = <DateTime>[
      for (int back = 6; back >= 0; back--)
        DateTime(today.year, today.month, today.day - back),
    ];
    final int highest = <int>[
      for (final DateTime d in week) state.dayFor(d)?.screenOnMs ?? 0,
      1,
    ].reduce((int a, int b) => a > b ? a : b);
    final int? average = state.averageMs;
    final TextTheme textStyles = context.textStyles;
    final ColorScheme colors = context.colors;
    const double chartHeight = 96;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Last 7 days',
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (average != null)
              Text(
                'Average ${formatDuration(Duration(milliseconds: average))} a day',
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: _tabular,
                ),
              ),
            AppSpacing.gapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final DateTime d in week)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          '${DateFormat('EEEE').format(d)}, '
                          '${formatDuration(Duration(milliseconds: state.dayFor(d)?.screenOnMs ?? 0))}',
                      child: InkWell(
                        borderRadius: AppRadius.small,
                        onTap: () => ref
                            .read(phoneControllerProvider.notifier)
                            .select(d),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                height: chartHeight,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    height: state.dayFor(d) == null
                                        ? 2
                                        : (chartHeight *
                                                  state.dayFor(d)!.screenOnMs /
                                                  highest)
                                              .clamp(2, chartHeight),
                                    decoration: BoxDecoration(
                                      color: d == state.selected
                                          ? colors.primary
                                          : colors.primaryContainer,
                                      borderRadius: AppRadius.small,
                                      border: Border.all(
                                        color: colors.outlineVariant,
                                        width: 0.75,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AppSpacing.gapXs,
                              Text(
                                DateFormat('E').format(d).substring(0, 1),
                                style: textStyles.labelSmall?.copyWith(
                                  fontWeight: d == state.selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppsCard extends StatelessWidget {
  const _AppsCard({required this.state});

  final PhoneState state;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool isToday =
        state.selected == DateTime(now.year, now.month, now.day);
    final List<AppUsage> top = state.apps.take(5).toList();
    final int most = top.isEmpty ? 1 : top.first.ms;
    final TextTheme textStyles = context.textStyles;
    final ColorScheme colors = context.colors;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isToday
                  ? 'Top apps today'
                  : 'Top apps on ${DateFormat('EEE, MMM d').format(state.selected)}',
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapMd,
            if (top.isEmpty)
              Text(
                state.dayFor(state.selected) == null
                    ? 'No record for this day.'
                    : 'No app time yet.',
                style: textStyles.bodyMedium,
              )
            else
              for (final AppUsage app in top)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              app.label,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            formatDuration(Duration(milliseconds: app.ms)),
                            style: textStyles.bodyMedium?.copyWith(
                              fontFeatures: _tabular,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: AppRadius.pill,
                        child: LinearProgressIndicator(
                          value: app.ms / most,
                          minHeight: 4,
                          color: colors.primary,
                          backgroundColor: colors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
