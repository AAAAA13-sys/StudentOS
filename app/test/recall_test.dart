import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/router/app_router.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/app_drawer.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/core/widgets/ponpon_talk.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/insights/insights_providers.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/notes/quiz_sheet.dart';
import 'package:studentos/features/notes/recall_item.dart';
import 'package:studentos/features/notes/recall_repository.dart';
import 'package:studentos/features/tasks/tasks_controller.dart';
import 'package:studentos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pumpAndSettle();
  }

  group('Drift v12 -> v13 migration & delete cascade', () {
    test('upgrades a v12 schema database and creates recall_reviews', () async {
      final AppDatabase db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('PRAGMA user_version = 12;');
            rawDb.execute(
              'CREATE TABLE notes ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'title TEXT NOT NULL, '
              'body TEXT NOT NULL, '
              'tags TEXT NOT NULL, '
              'created_at INTEGER NOT NULL, '
              'updated_at INTEGER NOT NULL, '
              'pinned INTEGER NOT NULL DEFAULT 0);',
            );
          },
        ),
      );
      addTearDown(db.close);

      expect(db.schemaVersion, greaterThanOrEqualTo(13));
      final RecallRepository repo = RecallRepository(db);
      final String key = recallCardKey('What is F=ma?');
      await repo.upsertReview(
        RecallReview(
          noteId: 1,
          cardKey: key,
          box: 2,
          nextReviewOn: '2026-11-26',
          lastReviewedAt: DateTime(2026, 11, 24),
          timesReviewed: 1,
        ),
      );
      final RecallReview? loaded = await repo.getReview(1, key);
      expect(loaded, isNotNull);
      expect(loaded!.box, 2);
      expect(loaded.nextReviewOn, '2026-11-26');
      expect(loaded.timesReviewed, 1);
    });

    test('NotesRepository.deleteNote deletes matching recall_reviews', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final NotesRepository notesRepo = NotesRepository(db);
      final RecallRepository recallRepo = RecallRepository(db);
      final int noteA = await notesRepo.createNote(
        const Note(id: 0, title: 'A', body: 'Q: q1\nA: a1', tags: <String>[]),
      );
      final int noteB = await notesRepo.createNote(
        const Note(id: 0, title: 'B', body: 'Q: q2\nA: a2', tags: <String>[]),
      );
      await recallRepo.upsertReview(
        RecallReview(
          noteId: noteA,
          cardKey: recallCardKey('q1'),
          box: 2,
          nextReviewOn: '2026-11-26',
          timesReviewed: 1,
        ),
      );
      await recallRepo.upsertReview(
        RecallReview(
          noteId: noteB,
          cardKey: recallCardKey('q2'),
          box: 3,
          nextReviewOn: '2026-11-28',
          timesReviewed: 2,
        ),
      );

      await notesRepo.deleteNote(noteA);
      final List<RecallReview> remaining = await recallRepo.getReviews();
      expect(remaining, hasLength(1));
      expect(remaining.single.noteId, noteB);
    });
  });

  group('Stable card keys & Leitner transitions', () {
    test('recallCardKey is deterministic across answer edits and handles duplicates', () {
      const Note original = Note(
        id: 1,
        title: 'Physics',
        body: 'Q: What is F=ma?\nA: Second law\nQ:   what  is  f=ma? \nA: Force equals mass times acceleration',
        tags: <String>[],
      );
      const Note editedAnswer = Note(
        id: 1,
        title: 'Physics',
        body: 'Q: What is F=ma?\nA: Updated explanation here\nQ: What is F=ma?\nA: Duplicate question updated',
        tags: <String>[],
      );

      final List<({RecallCard card, String key})> k1 = original.keyedRecallCards;
      final List<({RecallCard card, String key})> k2 =
          editedAnswer.keyedRecallCards;
      expect(k1, hasLength(2));
      expect(k1[0].key, k2[0].key);
      expect(k1[1].key, k2[1].key);
      expect(k1[0].key, isNot(k1[1].key));
      expect(k1[0].key, recallCardKey('What is F=ma?'));
      expect(k1[1].key, recallCardKey('What is F=ma?', occurrence: 1));
    });

    test('nextLeitnerReview advances boxes 1..5 with [1,2,4,7,14] and resets on Missed', () {
      final DateTime now = DateTime(2026, 11, 24, 10, 30);
      final String key = recallCardKey('ATP');

      final RecallReview b2 = nextLeitnerReview(
        noteId: 1,
        cardKey: key,
        box: 1,
        timesReviewed: 0,
        right: true,
        now: now,
      );
      expect(b2.box, 2);
      expect(b2.nextReviewOn, '2026-11-26'); // +2 days
      expect(b2.timesReviewed, 1);

      final RecallReview b3 = nextLeitnerReview(
        noteId: 1,
        cardKey: key,
        box: b2.box,
        timesReviewed: b2.timesReviewed,
        right: true,
        now: now,
      );
      expect(b3.box, 3);
      expect(b3.nextReviewOn, '2026-11-28'); // +4 days

      final RecallReview b4 = nextLeitnerReview(
        noteId: 1,
        cardKey: key,
        box: b3.box,
        timesReviewed: b3.timesReviewed,
        right: true,
        now: now,
      );
      expect(b4.box, 4);
      expect(b4.nextReviewOn, '2026-12-01'); // +7 days

      final RecallReview b5 = nextLeitnerReview(
        noteId: 1,
        cardKey: key,
        box: b4.box,
        timesReviewed: b4.timesReviewed,
        right: true,
        now: now,
      );
      expect(b5.box, 5);
      expect(b5.nextReviewOn, '2026-12-08'); // +14 days

      final RecallReview capped = nextLeitnerReview(
        noteId: 1,
        cardKey: key,
        box: 5,
        timesReviewed: b5.timesReviewed,
        right: true,
        now: now,
      );
      expect(capped.box, 5);
      expect(capped.nextReviewOn, '2026-12-08');

      final RecallReview missed = nextLeitnerReview(
        noteId: 1,
        cardKey: key,
        box: 4,
        timesReviewed: 3,
        right: false,
        now: now,
      );
      expect(missed.box, 1);
      expect(missed.nextReviewOn, '2026-11-24'); // due today
      expect(missed.timesReviewed, 4);
    });

    test('buildRecallDeck prioritizes soonest upcoming exam, then weaker box', () {
      final DateTime now = DateTime(2026, 11, 24, 9);
      const Note general = Note(
        id: 1,
        title: 'General',
        body: 'Q: Gen A\nA: 1\nQ: Gen B\nA: 2',
        tags: <String>[],
      );
      const Note laterExamNote = Note(
        id: 2,
        title: 'History',
        body: 'Q: Hist Q\nA: H',
        tags: <String>[],
      );
      const Note soonerExamNote = Note(
        id: 3,
        title: 'Bio',
        body: 'Q: Bio Box2\nA: B2\nQ: Bio Box1\nA: B1',
        tags: <String>[],
      );

      final List<RecallReview> reviews = <RecallReview>[
        RecallReview(
          noteId: 3,
          cardKey: recallCardKey('Bio Box2'),
          box: 2,
          nextReviewOn: '2026-11-24',
          timesReviewed: 1,
        ),
        RecallReview(
          noteId: 3,
          cardKey: recallCardKey('Bio Box1'),
          box: 1,
          nextReviewOn: '2026-11-24',
          timesReviewed: 1,
        ),
        // Done/future review shouldn't be in dueCards.
        RecallReview(
          noteId: 1,
          cardKey: recallCardKey('Gen B'),
          box: 3,
          nextReviewOn: '2026-11-28',
          timesReviewed: 2,
        ),
      ];

      final List<CalendarEvent> events = <CalendarEvent>[
        CalendarEvent(
          id: 10,
          title: 'History Midterm',
          startsAt: DateTime(2026, 11, 27, 10),
          noteId: 2,
        ),
        CalendarEvent(
          id: 11,
          title: 'Bio Quiz',
          startsAt: DateTime(2026, 11, 25, 14),
          noteId: 3,
        ),
        // Done exam should not give priority.
        CalendarEvent(
          id: 12,
          title: 'General Exam',
          startsAt: DateTime(2026, 11, 24, 12),
          noteId: 1,
          done: true,
        ),
      ];

      final deck = buildRecallDeck(
        notes: const <Note>[general, laterExamNote, soonerExamNote],
        reviews: reviews,
        events: events,
        now: now,
      );

      expect(
        deck.dueCards.map((DeckCard c) => c.card.question).toList(),
        <String>['Bio Box1', 'Bio Box2', 'Hist Q', 'Gen A'],
      );
      expect(deck.dueCards.first.examCountdown, 'Tomorrow');
      expect(deck.examPriorityCount, 3);
      expect(deck.upcomingCards.single.card.question, 'Gen B');
      expect(deck.nextUpcomingDate, '2026-11-28');
    });
  });

  group('UI, QuizSheet persistence, routing & Ponpon flows', () {
    testWidgets(
      'Notes 3-segment switcher, Recall empty states (single Ponpon), /recall redirect, and Back pop',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: const StudentOSApp(),
          ),
        );
        await settle(tester);

        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(NavigationBar)),
        );

        // /recall redirects to /notes?view=recall while preserving 3 bottom tabs.
        container.read(routerProvider).go('/recall');
        await settle(tester);

        expect(container.read(notesViewProvider), NotesView.recall);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(find.byType(SegmentedButton<NotesView>), findsOneWidget);
        expect(find.text('Notes'), findsWidgets);
        expect(find.text('Tasks'), findsOneWidget);
        expect(find.text('Recall'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);

        // Empty state: single Ponpon and suppressed PonponTalk.
        expect(find.text('No recall cards yet'), findsOneWidget);
        expect(find.byType(Ponpon), findsOneWidget);
        expect(find.byType(PonponTalk), findsNothing);

        // Pressing Back on Notes > Recall pops to Notes > Notes first.
        final NavigatorState nav = tester.state(find.byType(Navigator).first);
        await nav.maybePop();
        await settle(tester);
        expect(container.read(notesViewProvider), NotesView.notes);
        expect(find.byTooltip('New note'), findsOneWidget);

        // Switch back to Recall via SegmentedButton.
        await tester.tap(find.text('Recall'));
        await settle(tester);
        expect(container.read(notesViewProvider), NotesView.recall);
      },
    );

    testWidgets(
      'QuizSheet and RecallPanel persist Got it / Missed into DB and show caught-up Ponpon',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime now = DateTime(2026, 11, 24, 9);

        late int noteId;
        await tester.runAsync(() async {
          noteId = await NotesRepository(db).createNote(
            const Note(
              id: 0,
              title: 'Chemistry',
              body: 'Q: Symbol for Gold?\nA: Au',
              tags: <String>[],
            ),
          );
          await CalendarRepository(db).createEvent(
            CalendarEvent(
              id: 0,
              title: 'Chem Exam',
              startsAt: DateTime(2026, 11, 25, 10),
              noteId: noteId,
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              ponponClockProvider.overrideWithValue(() => now),
            ],
            child: const StudentOSApp(),
          ),
        );
        await settle(tester);

        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(NavigationBar)),
        );
        container.read(routerProvider).go('/recall');
        await settle(tester);

        expect(find.text('1 due today'), findsOneWidget);
        expect(find.text('1 card linked to upcoming exams'), findsOneWidget);
        expect(find.text('Exam Tomorrow'), findsOneWidget);
        expect(find.text('Symbol for Gold?'), findsOneWidget);

        // Tap Review due (1) -> opens Recall deck sheet.
        await tester.tap(find.text('Review due (1)'));
        await settle(tester);

        await tester.tap(find.text('Tap to reveal answer'));
        await settle(tester);
        expect(find.text('Au'), findsOneWidget);

        await tester.tap(find.text('Got it'));
        await settle(tester);

        // Verify persisted in Drift DB.
        final List<RecallReview> saved = await tester.runAsync(
          () => RecallRepository(db).getReviews(),
        ) ?? const <RecallReview>[];
        expect(saved, hasLength(1));
        expect(saved.single.box, 2);
        expect(saved.single.nextReviewOn, '2026-11-26');
        expect(saved.single.timesReviewed, 1);

        // Close sheet -> RecallPanel now shows caught-up single sleepy Ponpon.
        Navigator.of(tester.element(find.text('Got it'))).pop();
        await settle(tester);

        expect(find.text('All caught up for today'), findsOneWidget);
        expect(find.text('Next review: 2026-11-26'), findsOneWidget);
        expect(find.byType(Ponpon), findsOneWidget);
        expect(find.byType(PonponTalk), findsNothing);
      },
    );

    testWidgets(
      'Single-note showQuizSheet persists Missed (box 1 due today) to DB',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime now = DateTime(2026, 11, 24, 11);

        const Note note = Note(
          id: 7,
          title: 'Bio',
          body: 'Osmosis :: Diffusion of water',
          tags: <String>[],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              ponponClockProvider.overrideWithValue(() => now),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (BuildContext context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () => showQuizSheet(context, note),
                      child: const Text('Open quiz'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.text('Open quiz'));
        await settle(tester);

        await tester.tap(find.text('Tap to reveal answer'));
        await settle(tester);
        await tester.tap(find.text('Missed'));
        await settle(tester);

        final RecallReview? row = await tester.runAsync<RecallReview?>(
          () => RecallRepository(db).getReview(7, recallCardKey('Osmosis')),
        );
        expect(row, isNotNull);
        expect(row!.box, 1);
        expect(row.nextReviewOn, '2026-11-24');
        expect(row.timesReviewed, 1);
      },
    );

    testWidgets('Ponpon reviewRecall action switches Notes to Recall', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime now = DateTime(2026, 11, 24, 9);

      await tester.runAsync(() async {
        final int noteId = await NotesRepository(db).createNote(
          const Note(
            id: 0,
            title: 'Anatomy',
            body: 'Q: Femur?\nA: Thigh bone',
            tags: <String>[],
          ),
        );
        await RecallRepository(db).upsertReview(
          RecallReview(
            noteId: noteId,
            cardKey: recallCardKey('Femur?'),
            box: 1,
            nextReviewOn: '2026-11-24',
            timesReviewed: 1,
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ponponClockProvider.overrideWithValue(() => now),
          ],
          child: const StudentOSApp(),
        ),
      );
      await settle(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );
      container.read(routerProvider).go('/notes');
      await settle(tester);

      expect(find.text('Review 1 due recall card.'), findsOneWidget);
      await tester.tap(find.text('Review deck'));
      await settle(tester);

      expect(container.read(notesViewProvider), NotesView.recall);
      expect(find.text('Femur?'), findsOneWidget);
    });

    test('AppDrawer.formatRestoreSummary includes non-zero recallReviews', () {
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 2,
          notes: 3,
          recallReviews: 5,
        ),
        'Restored 1 event, 2 transactions, 3 notes and 5 recall cards',
      );
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 1,
          notes: 1,
          recallReviews: 1,
        ),
        'Restored 1 event, 1 transaction, 1 note and 1 recall card',
      );
    });
  });
}
