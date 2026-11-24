import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ponpon_talk.dart';
import '../calendar/schedule_view.dart';
import '../finance/goals_controller.dart';
import '../focus/clock_panels.dart';
import '../focus/focus_controller.dart';
import '../notes/note.dart';
import '../notes/notes_controller.dart';
import '../notes/quiz_sheet.dart';
import '../tasks/tasks_controller.dart';
import 'insights_providers.dart';
import 'month_review_screen.dart';
import 'ponpon_insight.dart';

/// Ponpon's talk bubble for one screen: reads that screen's insights, hides
/// itself once closed this session, and takes no room when there is nothing
/// to say or when [suppress] is set (the screen already shows an empty-state
/// Ponpon).
class PonponTalkSlot extends ConsumerWidget {
  const PonponTalkSlot({
    required this.surface,
    this.suppress = false,
    this.horizontalPadding = AppSpacing.lg,
    super.key,
  });

  final PonponSurface surface;
  final bool suppress;

  /// Side padding; zero where the parent already pads the screen edges.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (suppress) return const SizedBox.shrink();
    if (ref.watch(ponponDismissalsProvider).contains(surface)) {
      return const SizedBox.shrink();
    }
    final List<PonponInsight> insights = switch (surface) {
      PonponSurface.calendar => ref.watch(calendarInsightsProvider),
      PonponSurface.finance =>
        ref.watch(financeInsightsProvider).value ?? const <PonponInsight>[],
      PonponSurface.notes => ref.watch(notesInsightsProvider),
    };
    if (insights.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xs,
      ),
      child: PonponTalk(
        insights: insights,
        onClose: () =>
            ref.read(ponponDismissalsProvider.notifier).dismiss(surface),
        onInsightAction: (PonponInsight insight) =>
            runPonponInsightAction(context, ref, insight),
      ),
    );
  }
}

/// Runs [insight.action], arming [insight.focusTarget] when starting Focus.
void runPonponInsightAction(
  BuildContext context,
  WidgetRef ref,
  PonponInsight insight,
) {
  final PonponAction? action = insight.action;
  if (action == null) return;
  if (action == PonponAction.startFocus && insight.focusTarget != null) {
    unawaited(
      ref
          .read(focusControllerProvider.notifier)
          .setIntention(insight.focusTarget),
    );
  }
  runPonponAction(context, ref, action);
}

/// The first note, in list order, that has quiz cards.
Note? firstQuizNote(List<Note> notes) {
  for (final Note n in notes) {
    if (n.recallCards.isNotEmpty) return n;
  }
  return null;
}

/// Does what a tip's button promises. The tips sit on their own tab, so no
/// tab switch is needed: Focus is a view of Calendar, and the quiz opens as a
/// sheet over Notes.
void runPonponAction(BuildContext context, WidgetRef ref, PonponAction action) {
  switch (action) {
    case PonponAction.startFocus:
      ref.read(calendarViewProvider.notifier).show(CalendarView.focus);
    case PonponAction.seeWeek:
      ref.read(calendarViewProvider.notifier).show(CalendarView.schedule);
      ref.read(scheduleViewProvider.notifier).show(ScheduleView.week);
    case PonponAction.quizNotes:
      final Note? note = firstQuizNote(
        ref.read(notesControllerProvider).value?.notes ?? const <Note>[],
      );
      if (note != null) showQuizSheet(context, note);
    case PonponAction.reviewRecall:
      ref.read(notesViewProvider.notifier).show(NotesView.recall);
      GoRouter.maybeOf(context)?.go('/notes?view=recall');
    case PonponAction.seeTasks:
      ref.read(notesViewProvider.notifier).show(NotesView.tasks);
      GoRouter.maybeOf(context)?.go('/notes?view=tasks');
    case PonponAction.seeAlarms:
      ref.read(calendarViewProvider.notifier).show(CalendarView.alarm);
    case PonponAction.seeGoals:
      ref.read(financeViewProvider.notifier).show(FinanceView.goals);
      GoRouter.maybeOf(context)?.go('/finance?view=goals');
    case PonponAction.seeIous:
      ref.read(financeViewProvider.notifier).show(FinanceView.ious);
      GoRouter.maybeOf(context)?.go('/finance?view=ious');
    case PonponAction.seeMonthReview:
      final GoRouter? router = GoRouter.maybeOf(context);
      if (router != null) {
        router.push('/review');
      } else {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(builder: (_) => const MonthReviewScreen()),
        );
      }
  }
}
