import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/focus/focus_controller.dart';
import '../../features/focus/focus_plan.dart';
import '../../features/focus/focus_platform.dart';
import '../../features/focus/clock_screen.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_drawer.dart';

/// Index of the Clock tab in the bottom bar.
const int clockTabIndex = 3;

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _followAndroid();
        ref.read(focusControllerProvider.notifier).resumed();
      },
    );
    ref.read(focusPlatformProvider).onRouteWaiting(_followAndroid);
    WidgetsBinding.instance.addPostFrameCallback((_) => _followAndroid());
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
        shell.goBranch(0);
      case 'finance':
        shell.goBranch(1);
      case 'clock':
        ref.read(clockPanelProvider.notifier).show(ClockPanel.alarm);
        shell.goBranch(clockTabIndex);
      case 'start_focus':
        ref.read(clockPanelProvider.notifier).show(ClockPanel.focus);
        shell.goBranch(clockTabIndex);
        await _startFocusFromWidget();
      default:
        if (isTimerRoute(route)) {
          ref.read(clockPanelProvider.notifier).show(ClockPanel.focus);
          shell.goBranch(clockTabIndex);
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

    return Scaffold(
      drawer: const AppDrawer(),
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (session != null && shell.currentIndex != clockTabIndex)
            _FocusBanner(
              session: session,
              onTap: () {
                ref.read(clockPanelProvider.notifier).show(ClockPanel.focus);
                shell.goBranch(clockTabIndex);
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
                NavigationDestination(
                  icon: Icon(Icons.alarm_outlined),
                  selectedIcon: Icon(Icons.alarm_rounded),
                  label: 'Clock',
                ),
              ],
            ),
          ),
        ],
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
          height: 40,
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
