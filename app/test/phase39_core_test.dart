import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/ponpon_talk.dart';
import 'package:studentos/features/calendar/calendar_controller.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/focus/clock_panels.dart';
import 'package:studentos/features/insights/insights_providers.dart';
import 'package:studentos/features/insights/notes_insights.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/insights/ponpon_talk_slot.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_controller.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_controller.dart';

class _Events extends CalendarController {
  _Events(this.list);
  final List<CalendarEvent> list;

  @override
  Future<List<CalendarEvent>> build() async => list;
}

class _Shifts extends WorkController {
  @override
  Future<List<Shift>> build() async => <Shift>[];
}

class _Notes extends NotesController {
  _Notes(this.list);
  final List<Note> list;

  @override
  Future<NotesState> build() async =>
      NotesState(notes: list, tags: const <String>[]);
}

Widget _host(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  ),
);

void main() {
  group('tip actions', () {
    testWidgets('PonponTalk shows the action and reports it', (tester) async {
      PonponAction? got;
      await tester.pumpWidget(
        _host(
          PonponTalk(
            insights: const <PonponInsight>[
              PonponInsight(
                text: 'Exam today. A focus session would help.',
                priority: 0,
                action: PonponAction.startFocus,
              ),
            ],
            onClose: () {},
            onAction: (PonponAction a) => got = a,
          ),
          const <Override>[],
        ),
      );
      await tester.tap(find.text('Focus'));
      expect(got, PonponAction.startFocus);
    });

    testWidgets('the exam tip opens Calendar > Focus', (tester) async {
      await tester.pumpWidget(
        _host(const PonponTalkSlot(surface: PonponSurface.calendar), <Override>[
          calendarInsightsProvider.overrideWithValue(const <PonponInsight>[
            PonponInsight(
              text: 'Exam tomorrow: Math.',
              priority: 1,
              action: PonponAction.startFocus,
            ),
          ]),
        ]),
      );
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(PonponTalk)),
      );
      expect(c.read(calendarViewProvider), CalendarView.schedule);
      await tester.tap(find.text('Focus'));
      expect(c.read(calendarViewProvider), CalendarView.focus);
    });

    testWidgets('the quiz tip opens the quiz of the first quizzable note', (
      tester,
    ) async {
      final List<Note> notes = <Note>[
        const Note(id: 1, title: 'Plain', body: 'nothing', tags: <String>[]),
        const Note(
          id: 2,
          title: 'Bio',
          body: 'Q: powerhouse?\nA: mitochondria',
          tags: <String>[],
        ),
      ];
      expect(firstQuizNote(notes)!.id, 2);
      await tester.pumpWidget(
        _host(const PonponTalkSlot(surface: PonponSurface.notes), <Override>[
          notesControllerProvider.overrideWith(() => _Notes(notes)),
          notesInsightsProvider.overrideWithValue(const <PonponInsight>[
            PonponInsight(
              text: '1 note has quiz cards. Quiz yourself?',
              priority: 2,
              action: PonponAction.quizNotes,
            ),
          ]),
        ]),
      );
      await tester.pumpAndSettle();
      // The Notes screen keeps this loaded; load it here as it would be.
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(PonponTalk)),
      );
      await tester.runAsync(() => c.read(notesControllerProvider.future));
      await tester.tap(find.text('Quiz me'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    test('the notes insight carries the quiz action', () {
      final List<PonponInsight> notes = notesInsights(
        notes: const <Note>[
          Note(id: 1, title: 'a', body: 'Q: x\nA: y', tags: <String>[]),
        ],
        now: DateTime(2026, 11, 17, 9),
      );
      expect(
        notes.firstWhere((i) => i.text.contains('Quiz')).action,
        PonponAction.quizNotes,
      );
    });
  });

  test('a note with open checklist items gets a tip naming it', () {
    final List<PonponInsight> out = notesInsights(
      notes: const <Note>[
        Note(
          id: 1,
          title: 'Groceries',
          body: '- [ ] milk\n- [x] eggs\n- [ ] rice\n- [ ] salt',
          tags: <String>[],
        ),
        Note(id: 2, title: 'Done', body: '- [x] a', tags: <String>[]),
      ],
      now: DateTime(2026, 11, 17, 9),
    );
    expect(out.map((i) => i.text), contains('3 unticked items in Groceries'));
    expect(
      notesInsights(
        notes: const <Note>[
          Note(id: 1, title: 'Done', body: '- [x] a', tags: <String>[]),
        ],
        now: DateTime(2026, 11, 17, 9),
      ),
      isEmpty,
    );
  });

  testWidgets('clock-dependent tips refresh every 30 seconds', (tester) async {
    DateTime clock = DateTime(2026, 11, 17, 7);
    final CalendarEvent event = CalendarEvent(
      id: 1,
      title: 'Chem lab',
      startsAt: DateTime(2026, 11, 17, 9, 30),
    );
    await tester.pumpWidget(
      _host(const PonponTalkSlot(surface: PonponSurface.calendar), <Override>[
        calendarControllerProvider.overrideWith(
          () => _Events(<CalendarEvent>[event]),
        ),
        workControllerProvider.overrideWith(_Shifts.new),
        ponponClockProvider.overrideWithValue(() => clock),
      ]),
    );
    await tester.pump();
    expect(find.byType(PonponTalk), findsNothing);

    clock = DateTime(2026, 11, 17, 7, 40);
    await tester.pump(const Duration(seconds: 15));
    expect(find.byType(PonponTalk), findsNothing);
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.textContaining('In 1 h 50 min'), findsOneWidget);
    // Unmount so the periodic timer is cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('backup reminder', () {
    final DateTime now = DateTime(2026, 11, 17, 15);

    test('relative label by calendar day', () {
      expect(backupAgeLabel(null, now), 'never');
      expect(backupAgeLabel(DateTime(2026, 11, 17, 1), now), 'today');
      expect(backupAgeLabel(DateTime(2026, 11, 16, 23, 59), now), 'yesterday');
      expect(backupAgeLabel(DateTime(2026, 11, 14), now), '3 days ago');
    });

    test('dot after 14 days, or never with data', () {
      expect(backupNeedsAttention(null, now, hasData: true), isTrue);
      expect(backupNeedsAttention(null, now, hasData: false), isFalse);
      expect(
        backupNeedsAttention(DateTime(2026, 11, 4), now, hasData: true),
        isFalse,
      );
      expect(
        backupNeedsAttention(DateTime(2026, 11, 3), now, hasData: true),
        isTrue,
      );
    });

    test('the time of the last backup is stored', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final BackupService service = BackupService(db);
      expect(await service.lastBackupAt(), isNull);
      expect(await service.hasData(), isFalse);
      await service.markBackedUp(DateTime(2026, 11, 17, 15));
      expect(await service.lastBackupAt(), DateTime(2026, 11, 17, 15));
    });

    test('restoring an old-format event fills done with false', () async {
      final AppDatabase source = AppDatabase(NativeDatabase.memory());
      final AppDatabase target = AppDatabase(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);
      await CalendarRepository(source).createEvent(
        CalendarEvent(
          id: 0,
          title: 'Old event',
          startsAt: DateTime(2026, 11, 20, 9),
        ),
      );
      final Map<String, dynamic> doc = jsonDecode(
        await BackupService(source).exportJson(),
      ) as Map<String, dynamic>;
      for (final Object? row in doc['events'] as List<dynamic>) {
        (row! as Map<String, dynamic>).remove('done');
      }
      final counts = await BackupService(target).restoreJson(jsonEncode(doc));
      expect(counts.events, 1);
      final EventRow row = (await target.select(target.eventRows).get()).single;
      expect(row.done, isFalse);
    });
  });
}
