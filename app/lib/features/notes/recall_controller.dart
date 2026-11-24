import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../calendar/calendar_controller.dart';
import '../calendar/event.dart';
import '../calendar/widget_sync.dart';
import '../insights/insights_providers.dart';
import 'note.dart';
import 'notes_controller.dart';
import 'notes_repository.dart';
import 'recall_item.dart';
import 'recall_repository.dart';

class RecallDeckState {
  const RecallDeckState({
    required this.cards,
    required this.dueCards,
    required this.upcomingCards,
    required this.examPriorityCount,
    this.nextUpcomingDate,
  });

  static const RecallDeckState empty = RecallDeckState(
    cards: <DeckCard>[],
    dueCards: <DeckCard>[],
    upcomingCards: <DeckCard>[],
    examPriorityCount: 0,
  );

  final List<DeckCard> cards;
  final List<DeckCard> dueCards;
  final List<DeckCard> upcomingCards;
  final int examPriorityCount;
  final String? nextUpcomingDate;

  int dueCountForNote(int noteId) {
    int count = 0;
    for (final DeckCard card in dueCards) {
      if (card.note.id == noteId) count++;
    }
    return count;
  }
}

class RecallController extends AsyncNotifier<RecallDeckState> {
  RecallRepository get _repo => ref.read(recallRepositoryProvider);

  @override
  FutureOr<RecallDeckState> build() async {
    return _buildDeck();
  }

  Future<RecallDeckState> _buildDeck({DateTime? now}) async {
    final NotesState? currentNotes = ref.watch(notesControllerProvider).value;
    final NotesState notesState =
        currentNotes ?? await ref.watch(notesControllerProvider.future);
    if (!ref.mounted) return RecallDeckState.empty;

    final List<Note> notes;
    if (notesState.searchQuery.isEmpty && notesState.selectedTag == null) {
      notes = notesState.notes;
    } else {
      notes = await ref.read(notesRepositoryProvider).getNotes();
      if (!ref.mounted) return RecallDeckState.empty;
    }

    final List<CalendarEvent> events =
        ref.watch(calendarControllerProvider).value ??
        await ref
            .watch(calendarControllerProvider.future)
            .catchError((Object _) => const <CalendarEvent>[]);
    if (!ref.mounted) return RecallDeckState.empty;

    final List<RecallReview> reviews = await _repo.getReviews();
    if (!ref.mounted) return RecallDeckState.empty;

    final DateTime effectiveNow = now ?? ref.watch(ponponClockProvider)();
    final deck = buildRecallDeck(
      notes: notes,
      reviews: reviews,
      events: events,
      now: effectiveNow,
    );
    return RecallDeckState(
      cards: deck.cards,
      dueCards: deck.dueCards,
      upcomingCards: deck.upcomingCards,
      examPriorityCount: deck.examPriorityCount,
      nextUpcomingDate: deck.nextUpcomingDate,
    );
  }

  Future<void> recordOutcome(
    int noteId,
    String cardKey, {
    required bool right,
    DateTime? now,
  }) async {
    final DateTime at = now ?? ref.read(ponponClockProvider)();
    final RecallReview? existing = await _repo.getReview(noteId, cardKey);
    if (!ref.mounted) return;
    final RecallReview next = nextLeitnerReview(
      noteId: noteId,
      cardKey: cardKey,
      box: existing?.box ?? 1,
      timesReviewed: existing?.timesReviewed ?? 0,
      right: right,
      now: at,
    );
    await _repo.upsertReview(next);
    if (!ref.mounted) return;
    final RecallDeckState refreshed = await _buildDeck(now: at);
    if (!ref.mounted) return;
    state = AsyncData<RecallDeckState>(refreshed);
    unawaited(syncTodayWidget(ref.read(appDatabaseProvider)));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final AsyncValue<RecallDeckState> next = await AsyncValue.guard(_buildDeck);
    if (!ref.mounted) return;
    state = next;
    unawaited(syncTodayWidget(ref.read(appDatabaseProvider)));
  }
}

final AsyncNotifierProvider<RecallController, RecallDeckState>
recallControllerProvider =
    AsyncNotifierProvider<RecallController, RecallDeckState>(
      RecallController.new,
    );
