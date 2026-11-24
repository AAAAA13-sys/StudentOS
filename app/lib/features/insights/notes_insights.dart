import '../../core/checklist.dart';
import '../../core/widgets/ponpon.dart';
import '../calendar/event.dart';
import '../notes/note.dart';
import '../notes/recall_controller.dart';
import '../notes/recall_item.dart';
import '../tasks/task_item.dart';
import 'ponpon_insight.dart';

/// What Ponpon says about notes, recall cards, and tasks. With neither, it
/// says nothing, because the empty state already has Ponpon. Pure.
List<PonponInsight> notesInsights({
  required List<Note> notes,
  List<CalendarEvent> events = const <CalendarEvent>[],
  List<TaskItem> tasks = const <TaskItem>[],
  List<DeckCard>? dueRecallCards,
  RecallDeckState? recallDeck,
  required DateTime now,
}) {
  if (notes.isEmpty && tasks.isEmpty) return const <PonponInsight>[];
  final List<PonponInsight> out = <PonponInsight>[];

  final List<TaskItem> openTasks = tasks
      .where((TaskItem t) => !t.done)
      .toList();
  final List<TaskItem> overdueTasks = openTasks
      .where((TaskItem t) => t.dueStatus(now) == TaskDueStatus.overdue)
      .toList();
  final List<TaskItem> todayTasks = openTasks
      .where((TaskItem t) => t.dueStatus(now) == TaskDueStatus.today)
      .toList();

  if (overdueTasks.isNotEmpty) {
    out.add(
      PonponInsight(
        text: overdueTasks.length == 1
            ? '1 task is past due: ${overdueTasks.first.title}.'
            : '${overdueTasks.length} tasks are past due. Want to check them?',
        mood: PonponMood.happy,
        priority: 1,
        action: PonponAction.seeTasks,
      ),
    );
  }
  if (todayTasks.isNotEmpty) {
    out.add(
      PonponInsight(
        text: todayTasks.length == 1
            ? 'Task due today: ${todayTasks.first.title}.'
            : '${todayTasks.length} tasks due today.',
        mood: PonponMood.focused,
        priority: 2,
        action: PonponAction.seeTasks,
      ),
    );
  } else if (overdueTasks.isEmpty && openTasks.isNotEmpty) {
    out.add(
      PonponInsight(
        text: openTasks.length == 1
            ? '1 open task waiting when you are ready.'
            : '${openTasks.length} open tasks waiting when you are ready.',
        priority: 3,
        action: PonponAction.seeTasks,
      ),
    );
  }

  // The next event within 24 hours that has a note attached.
  final Set<int> noteIds = <int>{for (final Note n in notes) n.id};
  ({CalendarEvent event, DateTime at})? review;
  for (final CalendarEvent e in events) {
    if (e.done) continue;
    final int? id = e.noteId;
    if (id == null || !noteIds.contains(id)) continue;
    final DateTime? at = e.nextOccurrence(now);
    if (at == null || at.difference(now) > const Duration(hours: 24)) continue;
    if (review == null || at.isBefore(review.at)) review = (event: e, at: at);
  }
  if (review != null) {
    out.add(
      PonponInsight(
        text:
            'Review your note before ${clockText(review.at)}: ${review.event.title}.',
        mood: PonponMood.focused,
        priority: 1,
      ),
    );
  }

  // Spaced recall & exam-linked quiz cards.
  final List<DeckCard> effectiveDue =
      dueRecallCards ?? recallDeck?.dueCards ?? const <DeckCard>[];
  final List<DeckCard> soonExamCards = <DeckCard>[
    for (final DeckCard card in effectiveDue)
      if (card.examAt != null &&
          !card.examAt!.isBefore(now) &&
          card.examAt!.difference(now) <= const Duration(hours: 72))
        card,
  ];
  if (soonExamCards.isNotEmpty) {
    soonExamCards.sort((DeckCard a, DeckCard b) => a.examAt!.compareTo(b.examAt!));
    final DeckCard soonest = soonExamCards.first;
    final String examTitle = (soonest.examTitle ?? '').trim().isEmpty
        ? 'upcoming exam'
        : soonest.examTitle!.trim();
    final int count = soonExamCards
        .where(
          (DeckCard c) =>
              c.examAt == soonest.examAt && c.examTitle == soonest.examTitle,
        )
        .length;
    out.add(
      PonponInsight(
        text:
            'Exam soon ($examTitle): $count recall ${count == 1 ? 'card' : 'cards'} due.',
        mood: PonponMood.focused,
        priority: 1,
        action: PonponAction.reviewRecall,
      ),
    );
  } else {
    final bool hasDeckContext = recallDeck != null || dueRecallCards != null;
    final bool hasStartedReviews = (recallDeck?.cards ?? effectiveDue).any(
      (DeckCard c) => c.timesReviewed > 0,
    );
    if (!hasDeckContext || !hasStartedReviews) {
      // Notes holding Q:/A: or "term :: answer" quiz cards.
      final int quizzable = notes
          .where((Note n) => n.recallCards.isNotEmpty)
          .length;
      if (quizzable > 0) {
        out.add(
          PonponInsight(
            text: quizzable == 1
                ? '1 note has quiz cards. Quiz yourself?'
                : '$quizzable notes have quiz cards. Quiz yourself?',
            mood: PonponMood.focused,
            priority: 2,
            action: PonponAction.quizNotes,
          ),
        );
      }
    } else if (effectiveDue.isNotEmpty) {
      final int dueCount = effectiveDue.length;
      out.add(
        PonponInsight(
          text:
              'Review $dueCount due recall ${dueCount == 1 ? 'card' : 'cards'}.',
          mood: PonponMood.focused,
          priority: 2,
          action: PonponAction.reviewRecall,
        ),
      );
    }
  }

  // The first note (in list order) with unticked checklist items.
  for (final Note n in notes) {
    final int open = parseChecklist(n.body).where((i) => !i.done).length;
    if (open == 0) continue;
    final String title = n.title.trim().isEmpty ? 'Untitled' : n.title.trim();
    out.add(
      PonponInsight(
        text: open == 1
            ? '1 unticked item in $title'
            : '$open unticked items in $title',
        priority: 2,
      ),
    );
    break;
  }

  // The tag on the most notes, when it is on at least two.
  final Map<String, int> tagCount = <String, int>{};
  for (final Note n in notes) {
    for (final String tag in n.tags.toSet()) {
      tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }
  }
  if (tagCount.isNotEmpty) {
    final List<MapEntry<String, int>> ranked = tagCount.entries.toList()
      ..sort((a, b) {
        final int c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    if (ranked.first.value >= 2) {
      out.add(
        PonponInsight(
          text:
              '#${ranked.first.key} is your most used tag (${ranked.first.value} notes).',
          priority: 3,
        ),
      );
    }
  }

  return rankInsights(out);
}
