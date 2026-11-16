import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/router/app_router.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/focus/clock_panels.dart';
import 'package:studentos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  Future<ProviderContainer> openApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const StudentOSApp(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    );
  }

  testWidgets('The bar has three tabs and no Clock tab', (
    WidgetTester tester,
  ) async {
    await openApp(tester);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Clock'),
      ),
      findsNothing,
    );
  });

  testWidgets('The old clock and focus routes open the Calendar tab', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await openApp(tester);
    expect(container.read(calendarViewProvider), CalendarView.schedule);

    container.read(routerProvider).go('/clock');
    await settle(tester);
    expect(container.read(calendarViewProvider), CalendarView.alarm);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.byType(SegmentedButton<CalendarView>), findsOneWidget);

    container.read(routerProvider).go('/focus');
    await settle(tester);
    expect(container.read(calendarViewProvider), CalendarView.focus);
  });

  testWidgets('Schedule shows five events at once on a phone screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      for (int i = 0; i < 7; i++) {
        await CalendarRepository(database).createEvent(
          CalendarEvent(
            id: 0,
            title: 'Event $i',
            startsAt: DateTime.now().add(Duration(minutes: 5 + i)),
          ),
        );
      }
    });
    await openApp(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await tester.pumpAndSettle();
    final double screenHeight = tester.view.physicalSize.height / 2.75;
    int visible = 0;
    for (int i = 0; i < 7; i++) {
      final Finder f = find.text('Event $i');
      if (f.evaluate().isEmpty) continue;
      if (tester.getBottomLeft(f).dy < screenHeight - 80) visible++;
    }
    expect(visible, greaterThanOrEqualTo(5));
  });
}
