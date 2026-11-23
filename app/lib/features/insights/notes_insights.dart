import '../../core/checklist.dart';
import '../../core/widgets/ponpon.dart';
import '../calendar/event.dart';
import '../notes/note.dart';
import 'ponpon_insight.dart';

/// What Ponpon says about notes. With no notes it says nothing, because the
/// empty state already has Ponpon. Pure.
List<PonponInsight> notesInsights({
  required List<Note> notes,
  List<CalendarEvent> events = const <CalendarEvent>[],
  required DateTime now,
}) {
  if (notes.isEmpty) return const <PonponInsight>[];
  final List<PonponInsight> out = <PonponInsight>[];

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
