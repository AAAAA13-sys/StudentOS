import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/calendar_controller.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/finance/bills_controller.dart';
import '../../features/finance/goals_controller.dart';
import '../../features/focus/focus_controller.dart';
import '../../features/focus/focus_plan.dart';
import '../../features/focus/focus_platform.dart';
import '../../features/focus/clock_panels.dart';
import '../../features/phone/phone_repository.dart';
import '../../features/phone/phone_usage.dart';
import '../../features/tasks/tasks_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_drawer.dart';
import 'capture_request.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  late final AppLifecycleListener _lifecycle;
  bool _phoneSyncInFlight = false;
  DateTime? _lastPhoneSyncAt;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _followAndroid();
        ref.read(focusControllerProvider.notifier).resumed();
        ref.read(calendarControllerProvider.notifier).syncReminders();
        ref.read(billsControllerProvider.notifier).refreshAutoLog();
        ref.invalidate(alarmSnoozesProvider);
        unawaited(_syncPhoneIfDue());
      },
    );
    ref.read(focusPlatformProvider).onRouteWaiting(_followAndroid);
    WidgetsBinding.instance.addPostFrameCallback((_) => _followAndroid());
  }

  Future<void> _syncPhoneIfDue() async {
    if (_phoneSyncInFlight) return;
    final DateTime now = DateTime.now();
    if (_lastPhoneSyncAt != null &&
        now.difference(_lastPhoneSyncAt!) < const Duration(hours: 1)) {
      return;
    }
    _phoneSyncInFlight = true;
    try {
      // Check Usage access BEFORE touching phone_days or settings.
      final bool access = await ref.read(phoneUsageSourceProvider).hasAccess();
      if (!access || !mounted) return;
      final bool synced = await ref.read(phoneRepositoryProvider).sync(now);
      if (synced) {
        _lastPhoneSyncAt = now;
      }
    } on PlatformException {
      // Best-effort silent background sync.
    } on MissingPluginException {
      // Best-effort silent background sync.
    } catch (_) {
      // Best-effort silent background sync.
    } finally {
      _phoneSyncInFlight = false;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Opens the screen Android asked for: a home-screen widget tap, the
  /// focus notification, or strict lockdown sending the user back.
  Future<void> _followAndroid() async {
    final String? route = await ref.read(focusPlatformProvider).takeRoute();
    if (!mounted || route == null) return;
    final StatefulNavigationShell shell = widget.navigationShell;
    switch (route) {
      case 'calendar':
        ref.read(calendarViewProvider.notifier).show(CalendarView.schedule);
        ref.read(calendarShowTodayProvider.notifier).request();
        shell.goBranch(0);
      case 'finance':
        ref.read(financeViewProvider.notifier).show(FinanceView.cashflow);
        shell.goBranch(1);
      case 'clock':
        ref.read(calendarViewProvider.notifier).show(CalendarView.alarm);
        shell.goBranch(0);
      case 'start_focus':
        ref.read(calendarViewProvider.notifier).show(CalendarView.focus);
        shell.goBranch(0);
        await _startFocusFromWidget();
      case 'add_expense' || 'add_note' || 'add_event':
        final CaptureAction action = CaptureAction.fromRoute(route)!;
        switch (action) {
          case CaptureAction.addExpense:
            shell.goBranch(1);
          case CaptureAction.addNote:
            ref.read(notesViewProvider.notifier).show(NotesView.notes);
            shell.goBranch(2);
          case CaptureAction.addEvent:
            ref.read(calendarViewProvider.notifier).show(CalendarView.schedule);
            shell.goBranch(0);
        }
        ref.read(captureRequestProvider.notifier).request(action);
      default:
        if (route.startsWith('day:')) {
          final DateTime? day = DateTime.tryParse(route.substring(4));
          if (day == null) return;
          ref.read(calendarViewProvider.notifier).show(CalendarView.schedule);
          ref.read(calendarShowDayProvider.notifier).show(day);
          shell.goBranch(0);
        } else if (isTimerRoute(route)) {
          ref.read(calendarViewProvider.notifier).show(CalendarView.focus);
          shell.goBranch(0);
        }
    }
  }

  /// The Clock widget's Start focus button. Starts a session with the saved
  /// settings unless one is running, or strict lockdown is chosen but its
  /// service is off (the timer panel then explains what to turn on).
  Future<void> _startFocusFromWidget() async {
    final FocusState focus = await ref.read(focusControllerProvider.future);
    if (focus.session != null) return;
    if (focus.settings.lockdown == Lockdown.strict) {
      final PhoneReadiness ready = await ref
          .read(focusPlatformProvider)
          .readiness();
      if (!ready.accessibility) return;
    }
    await ref.read(focusControllerProvider.notifier).start();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final StatefulNavigationShell shell = widget.navigationShell;
    final FocusSession? session = ref
        .watch(focusControllerProvider)
        .value
        ?.session;

    final CalendarView view = ref.watch(calendarViewProvider);
    final bool onCalendar = shell.currentIndex == 0;
    final FinanceView financeView = ref.watch(financeViewProvider);
    final bool onFinance = shell.currentIndex == 1;
    final NotesView notesView = ref.watch(notesViewProvider);
    final bool onNotes = shell.currentIndex == 2;

    // Back on Alarms/Focus returns to Schedule first; Back on Finance > Goals
    // or IOUs returns to Finance > Cashflow first; Back on Notes > Tasks
    // returns to Notes > Notes first.
    return PopScope(
      canPop:
          !(onCalendar && view != CalendarView.schedule) &&
          !(onFinance && financeView != FinanceView.cashflow) &&
          !(onNotes && notesView != NotesView.notes),
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          if (onCalendar && view != CalendarView.schedule) {
            ref.read(calendarViewProvider.notifier).show(CalendarView.schedule);
          } else if (onFinance && financeView != FinanceView.cashflow) {
            ref.read(financeViewProvider.notifier).show(FinanceView.cashflow);
          } else if (onNotes && notesView != NotesView.notes) {
            ref.read(notesViewProvider.notifier).show(NotesView.notes);
          }
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        body: shell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (session != null && !(onCalendar && view == CalendarView.focus))
              _FocusBanner(
                session: session,
                onTap: () {
                  ref
                      .read(calendarViewProvider.notifier)
                      .show(CalendarView.focus);
                  shell.goBranch(0);
                },
              ),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: colors.outlineVariant, width: 1.0),
                ),
              ),
              child: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: (int index) {
                  shell.goBranch(
                    index,
                    initialLocation: index == shell.currentIndex,
                  );
                },
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                    label: 'Finance',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.article_outlined),
                    selectedIcon: Icon(Icons.article_rounded),
                    label: 'Notes',
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

/// A running focus session, shown above the bottom bar on every other tab.
class _FocusBanner extends ConsumerWidget {
  const _FocusBanner({required this.session, required this.onTap});

  final FocusSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(secondsProvider).value ?? DateTime.now();
    final ColorScheme colors = context.colors;
    final FocusPhase? phase = session.phaseAt(now);
    // Over: the controller's own ticker closes it out.
    if (phase == null) return const SizedBox.shrink();
    return Material(
      color: colors.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                phase.kind.isBreak ? Icons.coffee_rounded : Icons.timer_rounded,
                size: AppSizes.iconSm,
                color: colors.onPrimaryContainer,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  session.paused
                      ? '${phase.kind.label} paused'
                      : '${phase.kind.label} · round ${phase.round} of '
                            '${session.totalRounds}',
                  style: context.textStyles.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              Text(
                clock(session.remaining(now)),
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
