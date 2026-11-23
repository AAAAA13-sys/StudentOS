import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/app_drawer.dart';
import 'package:studentos/core/widgets/app_top_bar.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/features/focus/alarm.dart';
import 'package:studentos/features/focus/clock_panels.dart';
import 'package:studentos/features/focus/focus_platform.dart';
import 'package:studentos/features/focus/focus_repository.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_controller.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/notes/notes_screen.dart';
import 'package:studentos/features/work/day_shifts.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';

class _TestFocusPlatform implements FocusPlatform {
  @override
  Future<void> syncAlarms(List<Map<String, Object?>> alarms) async {}

  @override
  Future<List<int>> takeFiredOnce() async => <int>[];

  @override
  Future<Map<int, DateTime>> snoozes() async => <int, DateTime>{};

  @override
  Future<void> testAlarm(Map<String, Object?> alarm) async {}

  @override
  Future<({String uri, String name})?> pickSound(String? current) async => null;

  @override
  Future<PhoneReadiness> readiness() async => const PhoneReadiness();

  @override
  Future<void> openSetting(String which) async {}

  @override
  Future<void> startFocus(Map<String, Object?> session) async {}

  @override
  Future<void> stopFocus() async {}

  @override
  Future<void> setPinned(bool pinned) async {}

  @override
  Future<List<InstalledApp>> launchableApps() async => <InstalledApp>[];

  @override
  Future<String?> takeRoute() async => null;

  @override
  Future<bool> pinWidget(String which) async => false;

  @override
  void onRouteWaiting(void Function() onRoute) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  group('Edit-shift delete and feedback parity', () {
    testWidgets('updating a shift shows feedback snackbar', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime day = DateTime(2026, 11, 20);

      await tester.runAsync(() {
        return WorkRepository(db).createShifts(<Shift>[
          Shift(
            id: 0,
            job: 'Cafe',
            startsAt: DateTime(2026, 11, 20, 9),
            durationMinutes: 240,
          ),
        ]);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: DayShifts(day: day)),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.text('Shift at Cafe'));
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Roastery');
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      expect(find.text('Updated shift at Roastery'), findsOneWidget);
      expect(find.text('Shift at Roastery'), findsOneWidget);
    });

    testWidgets('deleting an unpaid single shift from editShift removes it', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime day = DateTime(2026, 11, 20);

      await tester.runAsync(() {
        return WorkRepository(db).createShifts(<Shift>[
          Shift(
            id: 0,
            job: 'Bookshop',
            startsAt: DateTime(2026, 11, 20, 13),
            durationMinutes: 180,
          ),
        ]);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: DayShifts(day: day)),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.text('Shift at Bookshop'));
      await settle(tester);

      await tester.scrollUntilVisible(
        find.text('Delete shift'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete shift'));
      await settle(tester);

      expect(find.text('Remove this shift?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await settle(tester);

      expect(find.text('Removed shift at Bookshop'), findsOneWidget);
      expect(find.text('Shift at Bookshop'), findsNothing);
      final List<Shift> remaining = (await tester.runAsync(
        () => WorkRepository(db).getShifts(),
      ))!;
      expect(remaining, isEmpty);
    });

    testWidgets(
      'deleting a paid shift from editShift shows paid warning and removes it',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime day = DateTime(2026, 11, 20);

        await tester.runAsync(() async {
          final WorkRepository repo = WorkRepository(db);
          await repo.createShifts(<Shift>[
            Shift(
              id: 0,
              job: 'Library',
              startsAt: DateTime(2026, 11, 20, 10),
              durationMinutes: 120,
              hourlyRateCents: 10000,
            ),
          ]);
          final Shift created = (await repo.getShifts()).single;
          await repo.markPaid(<int>[created.id]);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(body: DayShifts(day: day)),
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.text('Shift at Library'));
        await settle(tester);

        await tester.scrollUntilVisible(
          find.text('Delete shift'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Delete shift'));
        await settle(tester);

        expect(find.text('Remove a paid shift?'), findsOneWidget);
        expect(find.textContaining('was already paid'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
        await settle(tester);

        expect(find.text('Removed shift at Library'), findsOneWidget);
        expect(find.text('Shift at Library'), findsNothing);
      },
    );

    testWidgets(
      'deleting a recurring shift from editShift offers Only this and This and later',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime day1 = DateTime(2026, 11, 20);

        await tester.runAsync(() {
          return WorkRepository(db).createShifts(<Shift>[
            Shift(
              id: 0,
              job: 'Lab',
              startsAt: DateTime(2026, 11, 20, 15),
              durationMinutes: 120,
            ),
            Shift(
              id: 0,
              job: 'Lab',
              startsAt: DateTime(2026, 11, 27, 15),
              durationMinutes: 120,
            ),
          ]);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(body: DayShifts(day: day1)),
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.text('Shift at Lab'));
        await settle(tester);

        await tester.scrollUntilVisible(
          find.text('Delete shift'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Delete shift'));
        await settle(tester);

        expect(find.text('Only this'), findsOneWidget);
        expect(find.text('This and later'), findsOneWidget);
        await tester.tap(find.text('This and later'));
        await settle(tester);

        expect(find.text('Removed shifts at Lab'), findsOneWidget);
        final List<Shift> remaining = (await tester.runAsync(
          () => WorkRepository(db).getShifts(),
        ))!;
        expect(remaining, isEmpty);
      },
    );
  });

  group('Alarm card long-press delete parity', () {
    testWidgets(
      'tapping edits alarm and long-pressing confirms and deletes alarm',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.runAsync(() {
          return FocusRepository(db).createAlarm(
            const Alarm(id: 0, hour: 7, minute: 30, label: 'Morning class'),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              focusPlatformProvider.overrideWithValue(_TestFocusPlatform()),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: AlarmsPanel()),
            ),
          ),
        );
        await settle(tester);

        expect(find.text('Morning class'), findsOneWidget);

        // Tap opens editor.
        await tester.tap(find.text('Morning class'));
        await settle(tester);
        expect(find.text('Edit alarm'), findsOneWidget);
        Navigator.of(tester.element(find.text('Edit alarm'))).pop();
        await settle(tester);

        // Long-press opens confirmation; Cancel keeps alarm.
        await tester.longPress(find.text('Morning class'));
        await settle(tester);
        expect(find.text('Delete this alarm?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await settle(tester);
        expect(find.text('Morning class'), findsOneWidget);

        // Long-press again and confirm Delete removes alarm.
        await tester.longPress(find.text('Morning class'));
        await settle(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await settle(tester);
        expect(find.text('Morning class'), findsNothing);
        expect(find.text('No alarms yet'), findsOneWidget);
      },
    );
  });

  group('Backup status badge live updates and restore summary', () {
    testWidgets(
      'AppTopBar backup dot reacts immediately to local writes and backups',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(appBar: AppTopBar(title: 'Calendar')),
            ),
          ),
        );
        await settle(tester);

        Badge badge() => tester.widget<Badge>(find.byType(Badge));
        expect(badge().isLabelVisible, isFalse);
        expect(find.byTooltip('Menu'), findsOneWidget);

        // Inserting a shift immediately shows the backup dot.
        await tester.runAsync(() {
          return WorkRepository(db).createShifts(<Shift>[
            Shift(
              id: 0,
              job: 'Cafe',
              startsAt: DateTime(2026, 11, 20, 17),
              durationMinutes: 180,
            ),
          ]);
        });
        await settle(tester);

        expect(badge().isLabelVisible, isTrue);
        expect(find.byTooltip('Menu, a backup is due'), findsOneWidget);

        // Marking backed up immediately clears the dot.
        await tester.runAsync(
          () => BackupService(db).markBackedUp(DateTime.now()),
        );
        await settle(tester);

        expect(badge().isLabelVisible, isFalse);
        expect(find.byTooltip('Menu'), findsOneWidget);
      },
    );

    test('AppDrawer.formatRestoreSummary includes non-zero bills, shifts, alarms', () {
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 2,
          notes: 3,
        ),
        'Restored 1 event, 2 transactions and 3 notes',
      );
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 0,
          notes: 1,
          bills: 2,
          shifts: 1,
          alarms: 3,
        ),
        'Restored 1 event, 0 transactions, 1 note, 2 bills, 1 shift and 3 alarms',
      );
    });
  });

  group('Notes untagging trap and combined filter empty state', () {
    testWidgets(
      'untagging the last note for a selected tag clears selectedTag cleanly',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        late int bioId;

        await tester.runAsync(() async {
          final NotesRepository repo = NotesRepository(db);
          bioId = await repo.createNote(
            const Note(
              id: 0,
              title: 'Cell Lab',
              body: 'Mitosis',
              tags: <String>['bio'],
            ),
          );
          await repo.createNote(
            const Note(
              id: 0,
              title: 'Essay',
              body: 'Draft',
              tags: <String>['english'],
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const NotesScreen(),
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.widgetWithText(FilterChip, '#bio'));
        await settle(tester);
        expect(find.text('Cell Lab'), findsOneWidget);
        expect(find.text('Essay'), findsNothing);

        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(NotesScreen)),
        );
        await tester.runAsync(
          () => container.read(notesControllerProvider.notifier).updateNote(
                bioId,
                title: 'Cell Lab',
                body: 'Mitosis',
                tags: const <String>[],
              ),
        );
        await settle(tester);

        expect(container.read(notesControllerProvider).value?.selectedTag, isNull);
        expect(find.text('Essay'), findsOneWidget);
      },
    );

    testWidgets(
      'combined tag and search empty state shows smug Ponpon and clears both',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.runAsync(() async {
          final NotesRepository repo = NotesRepository(db);
          await repo.createNote(
            const Note(
              id: 0,
              title: 'Algebra',
              body: 'Vectors',
              tags: <String>['math'],
            ),
          );
          await repo.createNote(
            const Note(
              id: 0,
              title: 'Sonnet',
              body: 'Poem',
              tags: <String>['lit'],
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const NotesScreen(),
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.widgetWithText(FilterChip, '#math'));
        await settle(tester);
        await tester.enterText(find.byType(TextField), 'sonnet');
        await settle(tester);

        expect(find.text('No notes match "sonnet" in #math'), findsOneWidget);
        expect(find.text('Clear filters'), findsOneWidget);
        final Ponpon ponpon = tester.widget<Ponpon>(find.byType(Ponpon));
        expect(ponpon.mood, PonponMood.smug);

        await tester.tap(find.text('Clear filters'));
        await settle(tester);

        expect(find.text('Algebra'), findsOneWidget);
        expect(find.text('Sonnet'), findsOneWidget);
        expect(find.text('Clear filters'), findsNothing);
      },
    );
  });
}
