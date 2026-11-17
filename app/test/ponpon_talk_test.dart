import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/core/widgets/ponpon_talk.dart';
import 'package:studentos/features/insights/insights_providers.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/insights/ponpon_talk_slot.dart';

const List<PonponInsight> _three = <PonponInsight>[
  PonponInsight(text: 'First tip', priority: 0),
  PonponInsight(text: 'Second tip', priority: 1, mood: PonponMood.smug),
  PonponInsight(text: 'Third tip', priority: 2, mood: PonponMood.sleepy),
];

Widget _host(Widget child, {ThemeData? theme, List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? const <Override>[],
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

PonponMood _mood(WidgetTester tester) =>
    tester.widget<Ponpon>(find.byType(Ponpon)).mood;

void main() {
  group('PonponTalk', () {
    testWidgets('shows Ponpon and the first insight', (tester) async {
      await tester.pumpWidget(
        _host(PonponTalk(insights: _three, onClose: () {})),
      );
      expect(find.text('First tip'), findsOneWidget);
      expect(find.byType(Ponpon), findsOneWidget);
      expect(_mood(tester), PonponMood.happy);
    });

    testWidgets('tap cycles the text and the mood, then wraps', (tester) async {
      await tester.pumpWidget(
        _host(PonponTalk(insights: _three, onClose: () {})),
      );
      await tester.tap(find.text('First tip'));
      await tester.pumpAndSettle();
      expect(find.text('Second tip'), findsOneWidget);
      expect(find.text('First tip'), findsNothing);
      expect(_mood(tester), PonponMood.smug);

      await tester.tap(find.text('Second tip'));
      await tester.pumpAndSettle();
      expect(find.text('Third tip'), findsOneWidget);
      expect(_mood(tester), PonponMood.sleepy);

      await tester.tap(find.text('Third tip'));
      await tester.pumpAndSettle();
      expect(find.text('First tip'), findsOneWidget);
    });

    testWidgets('cross-fades: both tips exist mid-transition', (tester) async {
      await tester.pumpWidget(
        _host(PonponTalk(insights: _three, onClose: () {})),
      );
      await tester.tap(find.text('First tip'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('First tip'), findsOneWidget);
      expect(find.text('Second tip'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('First tip'), findsNothing);
    });

    testWidgets('close calls onClose', (tester) async {
      int closed = 0;
      await tester.pumpWidget(
        _host(PonponTalk(insights: _three, onClose: () => closed++)),
      );
      await tester.tap(find.byTooltip('Hide Ponpon tips'));
      expect(closed, 1);
    });

    testWidgets('renders nothing without insights', (tester) async {
      await tester.pumpWidget(
        _host(PonponTalk(insights: const <PonponInsight>[], onClose: () {})),
      );
      expect(find.byType(Ponpon), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('a single insight does not cycle', (tester) async {
      await tester.pumpWidget(
        _host(PonponTalk(insights: _three.sublist(0, 1), onClose: () {})),
      );
      await tester.tap(find.text('First tip'));
      await tester.pumpAndSettle();
      expect(find.text('First tip'), findsOneWidget);
    });

    testWidgets('is read as "Ponpon says" with a next-tip hint', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(PonponTalk(insights: _three, onClose: () {})),
      );
      expect(find.bySemanticsLabel('Ponpon says: First tip'), findsOneWidget);
      final SemanticsData data = tester
          .getSemantics(find.bySemanticsLabel('Ponpon says: First tip'))
          .getSemanticsData();
      expect(data.hint, 'Next tip');
      handle.dispose();
    });

    testWidgets('close button is at least 48dp', (tester) async {
      await tester.pumpWidget(
        _host(PonponTalk(insights: _three, onClose: () {})),
      );
      final Size size = tester.getSize(find.byTooltip('Hide Ponpon tips'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('works in the dark theme', (tester) async {
      await tester.pumpWidget(
        _host(
          PonponTalk(insights: _three, onClose: () {}),
          theme: AppTheme.dark,
        ),
      );
      expect(find.text('First tip'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PonponTalkSlot', () {
    List<Override> withInsights(List<PonponInsight> list) => <Override>[
      calendarInsightsProvider.overrideWithValue(list),
    ];

    testWidgets('shows the screen insights', (tester) async {
      await tester.pumpWidget(
        _host(
          const PonponTalkSlot(surface: PonponSurface.calendar),
          overrides: withInsights(_three),
        ),
      );
      expect(find.text('First tip'), findsOneWidget);
    });

    testWidgets('close hides it for the session', (tester) async {
      await tester.pumpWidget(
        _host(
          const PonponTalkSlot(surface: PonponSurface.calendar),
          overrides: withInsights(_three),
        ),
      );
      await tester.tap(find.byTooltip('Hide Ponpon tips'));
      await tester.pump();
      expect(find.byType(PonponTalk), findsNothing);
    });

    testWidgets('closing one screen leaves the others', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              PonponTalkSlot(surface: PonponSurface.calendar),
              PonponTalkSlot(surface: PonponSurface.notes),
            ],
          ),
          overrides: <Override>[
            calendarInsightsProvider.overrideWithValue(_three),
            notesInsightsProvider.overrideWithValue(_three),
          ],
        ),
      );
      expect(find.byType(PonponTalk), findsNWidgets(2));
      await tester.tap(find.byTooltip('Hide Ponpon tips').first);
      await tester.pump();
      expect(find.byType(PonponTalk), findsOneWidget);
    });

    testWidgets('absent with no insights', (tester) async {
      await tester.pumpWidget(
        _host(
          const PonponTalkSlot(surface: PonponSurface.calendar),
          overrides: withInsights(const <PonponInsight>[]),
        ),
      );
      expect(find.byType(PonponTalk), findsNothing);
    });

    testWidgets('absent when suppressed by an empty-state Ponpon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PonponTalkSlot(surface: PonponSurface.calendar, suppress: true),
          overrides: withInsights(_three),
        ),
      );
      expect(find.byType(PonponTalk), findsNothing);
    });
  });
}
