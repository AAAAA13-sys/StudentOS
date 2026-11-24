import 'dart:math' as math;

import '../calendar/event.dart';
import 'note.dart';

/// Leitner box intervals in days for boxes 1..5.
const List<int> leitnerIntervalsDays = <int>[1, 2, 4, 7, 14];

/// Formats a local calendar day as `YYYY-MM-DD`.
String formatRecallDateKey(DateTime date) {
  final String y = date.year.toString().padLeft(4, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parses a `YYYY-MM-DD` date key, returning null when malformed.
DateTime? parseRecallDateKey(String key) {
  final List<String> parts = key.split('-');
  if (parts.length != 3) return null;
  final int? y = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  final int? d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Persistent Leitner scheduling state for a single recall card.
class RecallReview {
  const RecallReview({
    required this.noteId,
    required this.cardKey,
    required this.box,
    required this.nextReviewOn,
    this.lastReviewedAt,
    this.timesReviewed = 0,
  });

  final int noteId;
  final String cardKey;
  final int box;
  final String nextReviewOn;
  final DateTime? lastReviewedAt;
  final int timesReviewed;

  /// True when scheduled on or before [today]'s calendar date.
  bool isDueOn(DateTime today) =>
      nextReviewOn.compareTo(formatRecallDateKey(today)) <= 0;
}

/// Pure Leitner transition for answering a recall card at [now].
///
/// - `right == true` ("Got it"): advances box `min(5, box + 1)` and schedules
///   `today + leitnerIntervalsDays[nextBox - 1]` days.
/// - `right == false` ("Missed"): resets to box `1` due `today`.
RecallReview nextLeitnerReview({
  required int noteId,
  required String cardKey,
  int box = 1,
  int timesReviewed = 0,
  required bool right,
  required DateTime now,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  if (right) {
    final int currentBox = box.clamp(1, leitnerIntervalsDays.length);
    final int nextBox = math.min(leitnerIntervalsDays.length, currentBox + 1);
    final int days = leitnerIntervalsDays[nextBox - 1];
    final DateTime due = DateTime(today.year, today.month, today.day + days);
    return RecallReview(
      noteId: noteId,
      cardKey: cardKey,
      box: nextBox,
      nextReviewOn: formatRecallDateKey(due),
      lastReviewedAt: now,
      timesReviewed: timesReviewed + 1,
    );
  }
  return RecallReview(
    noteId: noteId,
    cardKey: cardKey,
    box: 1,
    nextReviewOn: formatRecallDateKey(today),
    lastReviewedAt: now,
    timesReviewed: timesReviewed + 1,
  );
}

/// One active-recall card joined with its note, Leitner status, and any
/// linked upcoming exam context.
class DeckCard {
  const DeckCard({
    required this.note,
    required this.card,
    required this.cardKey,
    required this.box,
    required this.nextReviewOn,
    required this.timesReviewed,
    required this.isDue,
    this.examTitle,
    this.examAt,
    this.examCountdown,
  });

  final Note note;
  final RecallCard card;
  final String cardKey;
  final int box;
  final String nextReviewOn;
  final int timesReviewed;
  final bool isDue;
  final String? examTitle;
  final DateTime? examAt;
  final String? examCountdown;

  bool get isMastered => box >= 5 && !isDue;
}

/// Joins [notes], [reviews], and [events] into sorted due & upcoming deck lists.
({
  List<DeckCard> cards,
  List<DeckCard> dueCards,
  List<DeckCard> upcomingCards,
  int examPriorityCount,
  String? nextUpcomingDate,
})
buildRecallDeck({
  required List<Note> notes,
  required List<RecallReview> reviews,
  required List<CalendarEvent> events,
  required DateTime now,
}) {
  final String todayKey = formatRecallDateKey(now);
  final Map<(int, String), RecallReview> reviewMap =
      <(int, String), RecallReview>{
        for (final RecallReview r in reviews) (r.noteId, r.cardKey): r,
      };

  // Soonest upcoming non-done exam per noteId.
  final Map<int, ({String title, DateTime at, String? countdown})> examByNote =
      <int, ({String title, DateTime at, String? countdown})>{};
  for (final CalendarEvent event in events) {
    if (event.done || !event.isExam) continue;
    final int? noteId = event.noteId;
    if (noteId == null) continue;
    final DateTime? at = event.nextOccurrence(now);
    if (at == null) continue;
    final existing = examByNote[noteId];
    if (existing == null || at.isBefore(existing.at)) {
      examByNote[noteId] = (
        title: event.title,
        at: at,
        countdown: event.countdownBadge(now, on: at),
      );
    }
  }

  final List<({DeckCard card, int noteIndex, int cardIndex})> allIndexed =
      <({DeckCard card, int noteIndex, int cardIndex})>[];

  for (int noteIndex = 0; noteIndex < notes.length; noteIndex++) {
    final Note note = notes[noteIndex];
    final List<({RecallCard card, String key})> keyed = note.keyedRecallCards;
    final exam = examByNote[note.id];
    for (int cardIndex = 0; cardIndex < keyed.length; cardIndex++) {
      final ({RecallCard card, String key}) entry = keyed[cardIndex];
      final RecallReview? review = reviewMap[(note.id, entry.key)];
      final int box = (review?.box ?? 1).clamp(1, 5);
      final String nextReviewOn = review?.nextReviewOn ?? todayKey;
      final int timesReviewed = review?.timesReviewed ?? 0;
      final bool isDue = review == null ? true : review.isDueOn(now);
      allIndexed.add((
        card: DeckCard(
          note: note,
          card: entry.card,
          cardKey: entry.key,
          box: box,
          nextReviewOn: nextReviewOn,
          timesReviewed: timesReviewed,
          isDue: isDue,
          examTitle: exam?.title,
          examAt: exam?.at,
          examCountdown: exam?.countdown,
        ),
        noteIndex: noteIndex,
        cardIndex: cardIndex,
      ));
    }
  }

  int compareDue(
    ({DeckCard card, int noteIndex, int cardIndex}) a,
    ({DeckCard card, int noteIndex, int cardIndex}) b,
  ) {
    final DateTime? examA = a.card.examAt;
    final DateTime? examB = b.card.examAt;
    if (examA != null && examB == null) return -1;
    if (examA == null && examB != null) return 1;
    if (examA != null && examB != null) {
      final int byExam = examA.compareTo(examB);
      if (byExam != 0) return byExam;
    }
    final int byBox = a.card.box.compareTo(b.card.box);
    if (byBox != 0) return byBox;
    final int byDue = a.card.nextReviewOn.compareTo(b.card.nextReviewOn);
    if (byDue != 0) return byDue;
    final int byNote = a.noteIndex.compareTo(b.noteIndex);
    if (byNote != 0) return byNote;
    return a.cardIndex.compareTo(b.cardIndex);
  }

  final List<({DeckCard card, int noteIndex, int cardIndex})> dueIndexed =
      allIndexed.where((e) => e.card.isDue).toList()..sort(compareDue);
  final List<({DeckCard card, int noteIndex, int cardIndex})> upcomingIndexed =
      allIndexed.where((e) => !e.card.isDue).toList()..sort((a, b) {
        final int byDue = a.card.nextReviewOn.compareTo(b.card.nextReviewOn);
        return byDue != 0 ? byDue : compareDue(a, b);
      });

  final List<DeckCard> dueCards = <DeckCard>[
    for (final e in dueIndexed) e.card,
  ];
  final List<DeckCard> upcomingCards = <DeckCard>[
    for (final e in upcomingIndexed) e.card,
  ];
  final List<DeckCard> cards = <DeckCard>[for (final e in allIndexed) e.card];
  final int examPriorityCount = dueCards
      .where((DeckCard c) => c.examAt != null)
      .length;
  final String? nextUpcomingDate = upcomingCards.isEmpty
      ? null
      : upcomingCards.first.nextReviewOn;

  return (
    cards: cards,
    dueCards: dueCards,
    upcomingCards: upcomingCards,
    examPriorityCount: examPriorityCount,
    nextUpcomingDate: nextUpcomingDate,
  );
}
