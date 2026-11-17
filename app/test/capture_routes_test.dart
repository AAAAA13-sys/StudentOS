import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/widgets/capture_request.dart';
import 'package:studentos/features/focus/clock_panels.dart';
import 'package:studentos/features/focus/focus_platform.dart';
import 'package:studentos/main.dart';

import 'focus_test.dart' show FakeFocusPlatform;

/// Hands out one route at a time, as Android does, and can announce a new
/// one while the app is open (a warm start).
class _Android extends FakeFocusPlatform {
  _Android([this.route]);

  String? route;
  void Function()? _waiting;

  @override
  Future<String?> takeRoute() async {
    final String? r = route;
    route = null;
    return r;
  }

  @override
  void onRouteWaiting(void Function() onRoute) => _waiting = onRoute;

  void warm(String r) {
    route = r;
    _waiting!();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => database.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<ProviderContainer> open(WidgetTester tester, _Android android) async {
    // The event sheet's dropdowns overflow by a pixel or two with the test
    // font; that is the font, not these routes.
    final void Function(FlutterErrorDetails)? original = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          focusPlatformProvider.overrideWithValue(android),
        ],
        child: const StudentOSApp(),
      ),
    );
    await settle(tester);
    return ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    );
  }

  Future<void> closeSheet(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await settle(tester);
  }

  testWidgets('add_expense on a cold start opens the quick expense sheet', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await open(tester, _Android('add_expense'));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Finance'), findsWidgets);
    expect(c.read(captureRequestProvider), isNull);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('add_note on a cold start opens a new note editor', (
    WidgetTester tester,
  ) async {
    await open(tester, _Android('add_note'));
    expect(find.text('New Note'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
  });

  testWidgets('add_event on a cold start opens the new event sheet', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await open(tester, _Android('add_event'));
    expect(find.text('Save Event'), findsOneWidget);
    expect(c.read(calendarViewProvider), CalendarView.schedule);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets(
    'warm starts open each sheet once, and a resume does not reopen',
    (WidgetTester tester) async {
      final _Android android = _Android();
      await open(tester, android);
      expect(find.byType(BottomSheet), findsNothing);

      android.warm('add_note');
      await settle(tester);
      expect(find.text('New Note'), findsOneWidget);
      await closeSheet(tester);
      expect(find.text('New Note'), findsNothing);

      // Resume with nothing waiting: no sheet comes back.
      for (final AppLifecycleState st in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(st);
      }
      await settle(tester);
      expect(find.byType(BottomSheet), findsNothing);

      android.warm('add_expense');
      await settle(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      await closeSheet(tester);

      android.warm('add_event');
      await settle(tester);
      expect(find.text('Save Event'), findsOneWidget);
    },
  );

  testWidgets('an unknown route opens nothing', (WidgetTester tester) async {
    final _Android android = _Android('add_nonsense');
    final ProviderContainer c = await open(tester, android);
    expect(find.byType(BottomSheet), findsNothing);
    expect(c.read(captureRequestProvider), isNull);
    android.warm('add_');
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
  });

  test('CaptureAction.fromRoute maps only the three capture routes', () {
    expect(CaptureAction.fromRoute('add_expense'), CaptureAction.addExpense);
    expect(CaptureAction.fromRoute('add_note'), CaptureAction.addNote);
    expect(CaptureAction.fromRoute('add_event'), CaptureAction.addEvent);
    expect(CaptureAction.fromRoute('finance'), isNull);
    expect(CaptureAction.fromRoute('day:2026-01-01'), isNull);
  });
}
