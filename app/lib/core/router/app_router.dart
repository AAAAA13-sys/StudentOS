import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/calendar_screen.dart';
import '../../features/finance/finance_screen.dart';
import '../../features/finance/goals_controller.dart';
import '../../features/insights/month_review_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/focus/clock_panels.dart';
import '../../features/tasks/tasks_controller.dart';
import '../widgets/scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/calendar',
    routes: <RouteBase>[
      // The old Clock and Focus pages now live inside the Calendar tab.
      GoRoute(path: '/clock', redirect: (_, _) => '/calendar?view=alarm'),
      GoRoute(path: '/focus', redirect: (_, _) => '/calendar?view=focus'),
      // Tasks and Recall live inside the Notes tab; Goals and IOUs live inside Finance.
      GoRoute(path: '/tasks', redirect: (_, _) => '/notes?view=tasks'),
      GoRoute(path: '/recall', redirect: (_, _) => '/notes?view=recall'),
      GoRoute(path: '/goals', redirect: (_, _) => '/finance?view=goals'),
      GoRoute(path: '/ious', redirect: (_, _) => '/finance?view=ious'),
      GoRoute(
        path: '/review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const MonthReviewScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return ScaffoldWithNavBar(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/calendar',
                builder: (BuildContext context, GoRouterState state) =>
                    _ViewFromQuery(
                      view: state.uri.queryParameters['view'],
                      child: const CalendarScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/finance',
                builder: (BuildContext context, GoRouterState state) =>
                    _FinanceViewFromQuery(
                      view: state.uri.queryParameters['view'],
                      child: const FinanceScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/notes',
                builder: (BuildContext context, GoRouterState state) =>
                    _NotesViewFromQuery(
                      view: state.uri.queryParameters['view'],
                      child: const NotesScreen(),
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Opens the Calendar tab on the view named by `?view=` (`alarm`, `focus`).
class _ViewFromQuery extends ConsumerStatefulWidget {
  const _ViewFromQuery({required this.view, required this.child});

  final String? view;
  final Widget child;

  @override
  ConsumerState<_ViewFromQuery> createState() => _ViewFromQueryState();
}

class _ViewFromQueryState extends ConsumerState<_ViewFromQuery> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(_ViewFromQuery old) {
    super.didUpdateWidget(old);
    if (old.view != widget.view) _apply();
  }

  void _apply() {
    final CalendarView? view = switch (widget.view) {
      'alarm' => CalendarView.alarm,
      'focus' => CalendarView.focus,
      'schedule' => CalendarView.schedule,
      _ => null,
    };
    if (view == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(calendarViewProvider.notifier).show(view);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Opens the Notes tab on the view named by `?view=` (`notes`, `tasks`,
/// `recall`).
class _NotesViewFromQuery extends ConsumerStatefulWidget {
  const _NotesViewFromQuery({required this.view, required this.child});

  final String? view;
  final Widget child;

  @override
  ConsumerState<_NotesViewFromQuery> createState() =>
      _NotesViewFromQueryState();
}

class _NotesViewFromQueryState extends ConsumerState<_NotesViewFromQuery> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(_NotesViewFromQuery old) {
    super.didUpdateWidget(old);
    if (old.view != widget.view) _apply();
  }

  void _apply() {
    final NotesView? view = switch (widget.view) {
      'tasks' => NotesView.tasks,
      'recall' => NotesView.recall,
      'notes' => NotesView.notes,
      _ => null,
    };
    if (view == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notesViewProvider.notifier).show(view);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Opens the Finance tab on the view named by `?view=` (`cashflow`, `goals`,
/// `ious`).
class _FinanceViewFromQuery extends ConsumerStatefulWidget {
  const _FinanceViewFromQuery({required this.view, required this.child});

  final String? view;
  final Widget child;

  @override
  ConsumerState<_FinanceViewFromQuery> createState() =>
      _FinanceViewFromQueryState();
}

class _FinanceViewFromQueryState extends ConsumerState<_FinanceViewFromQuery> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(_FinanceViewFromQuery old) {
    super.didUpdateWidget(old);
    if (old.view != widget.view) _apply();
  }

  void _apply() {
    final FinanceView? view = switch (widget.view) {
      'goals' => FinanceView.goals,
      'ious' => FinanceView.ious,
      'cashflow' => FinanceView.cashflow,
      _ => null,
    };
    if (view == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(financeViewProvider.notifier).show(view);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
