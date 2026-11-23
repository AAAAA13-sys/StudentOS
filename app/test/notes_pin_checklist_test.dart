import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/checklist.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/notes/notes_screen.dart';

void main() {
  group('checklist parser', () {
    test('reads both marker forms and any case of x', () {
      final items = parseChecklist(
        '- [ ] milk\n[x] eggs\n- [X] rice\n[ ] salt\nplain line',
      );
      expect(items.map((i) => i.text), <String>[
        'milk',
        'eggs',
        'rice',
        'salt',
      ]);
      expect(items.map((i) => i.done), <bool>[false, true, true, false]);
    });

    test('ignores Q/A and :: lines and empty items', () {
      const String body =
          'Q: capital?\nA: Manila\nmito :: powerhouse\n- [ ]\n- [ ] a';
      expect(parseChecklist(body).map((i) => i.text), <String>['a']);
      expect(extractRecallCards(body), hasLength(2));
    });

    test('toggle changes the right line when two items share text', () {
      const String body = '- [ ] same\nQ: x\nA: y\n- [ ] same';
      final String once = toggleChecklistLine(body, 1);
      expect(once, '- [ ] same\nQ: x\nA: y\n- [x] same');
      expect(toggleChecklistLine(once, 1), body);
      expect(toggleChecklistLine('[X] a', 0), '[ ] a');
      expect(toggleChecklistLine(body, 9), body);
    });

    test('events keep working through the shared parser', () {
      final CalendarEvent e = CalendarEvent(
        id: 1,
        title: 't',
        startsAt: DateTime(2026, 11, 17),
        notes: '- [ ] a\n[x] b',
      );
      expect(e.checklistItems.length, 2);
      expect(e.toggleChecklistItem(0).notes, '- [x] a\n[x] b');
    });

    test('a checklist first line gives the item text as the title', () {
      expect(noteTitleFor('', '- [ ] Buy rice\n- [ ] Eggs'), 'Buy rice');
      expect(noteTitleFor('', '[x] Done thing'), 'Done thing');
      expect(noteTitleFor('Groceries', '- [ ] a'), 'Groceries');
    });
  });

  group('pinned notes', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('pinned sort first, in the list and in search', () async {
      final NotesRepository repo = NotesRepository(db);
      final int a = await repo.createNote(
        const Note(id: 0, title: 'Alpha', body: 'x', tags: <String>[]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await repo.createNote(
        const Note(id: 0, title: 'Beta', body: 'x', tags: <String>[]),
      );
      expect((await repo.getNotes()).map((n) => n.title), <String>[
        'Beta',
        'Alpha',
      ]);

      await repo.setPinned(a, pinned: true);
      expect((await repo.getNotes()).map((n) => n.title), <String>[
        'Alpha',
        'Beta',
      ]);
      expect((await repo.getNotes(q: 'x')).map((n) => n.title), <String>[
        'Alpha',
        'Beta',
      ]);
      expect((await repo.getNote(a))!.pinned, isTrue);
    });

    test('a new note is not pinned and migration default is false', () async {
      final int id = await NotesRepository(
        db,
      ).createNote(const Note(id: 0, title: 'n', body: '', tags: <String>[]));
      expect((await NotesRepository(db).getNote(id))!.pinned, isFalse);
      expect(db.schemaVersion, greaterThanOrEqualTo(7));
      await db
          .into(db.noteRows)
          .insert(
            NoteRowsCompanion.insert(
              title: 'raw',
              body: '',
              tags: '[]',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          );
      final rows = await db.select(db.noteRows).get();
      expect(rows.every((r) => r.pinned == false), isTrue);
    });

    test(
      'restoring an old backup without a pinned key defaults to false',
      () async {
        final AppDatabase target = AppDatabase(NativeDatabase.memory());
        addTearDown(target.close);
        final String json = jsonEncode(<String, Object?>{
          'app': 'studentos',
          'format': 1,
          'events': <Object?>[],
          'transactions': <Object?>[],
          'notes': <Object?>[
            <String, Object?>{
              'id': 1,
              'title': 'Old note',
              'body': '- [ ] a',
              'tags': '[]',
              'createdAt': 1700000000,
              'updatedAt': 1700000000,
            },
          ],
        });
        final counts = await BackupService(target).restoreJson(json);
        expect(counts.notes, 1);
        final Note note = (await NotesRepository(target).getNotes()).single;
        expect(note.pinned, isFalse);
        expect(note.checklistItems, hasLength(1));
      },
    );
  });

  group('notes screen', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: NotesScreen()),
        ),
      );
      await settle(tester);
    }

    testWidgets('tapping a checklist row ticks the line and strikes it', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(
        () => NotesRepository(db).createNote(
          const Note(
            id: 0,
            title: 'Groceries',
            body: 'Shop list\n- [ ] Rice\n- [x] Eggs\n- [ ] Salt',
            tags: <String>[],
          ),
        ),
      );
      await pumpScreen(tester);
      expect(find.text('1 of 3 done'), findsOneWidget);

      await tester.tap(find.text('Rice'));
      await settle(tester);

      final Note saved = (await tester.runAsync(
        () => NotesRepository(db).getNotes(),
      ))!.single;
      expect(saved.body, 'Shop list\n- [x] Rice\n- [x] Eggs\n- [ ] Salt');
      expect(find.text('2 of 3 done'), findsOneWidget);
      final Text rice = tester.widget<Text>(find.text('Rice'));
      expect(rice.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('a long checklist shows five rows and +N more', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(
        () => NotesRepository(db).createNote(
          Note(
            id: 0,
            title: 'Big',
            body: List<String>.generate(
              7,
              (int i) => '- [ ] item$i',
            ).join('\n'),
            tags: const <String>[],
          ),
        ),
      );
      await pumpScreen(tester);
      expect(find.text('item4'), findsOneWidget);
      expect(find.text('item5'), findsNothing);
      expect(find.text('+2 more'), findsOneWidget);
    });

    testWidgets('pinning a note moves it to the top', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final NotesRepository repo = NotesRepository(db);
        await repo.createNote(
          const Note(id: 0, title: 'First', body: '', tags: <String>[]),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        await repo.createNote(
          const Note(id: 0, title: 'Second', body: '', tags: <String>[]),
        );
      });
      await pumpScreen(tester);
      expect(
        tester.getTopLeft(find.text('Second')).dy,
        lessThan(tester.getTopLeft(find.text('First')).dy),
      );
      expect(find.text('Pinned'), findsNothing);

      final Finder pinFirst = find.descendant(
        of: find.ancestor(of: find.text('First'), matching: find.byType(Card)),
        matching: find.byTooltip('Pin note'),
      );
      await tester.tap(pinFirst);
      await settle(tester);

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('Others'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('First')).dy,
        lessThan(tester.getTopLeft(find.text('Second')).dy),
      );
      expect(find.byTooltip('Unpin note'), findsOneWidget);
    });
  });
}
