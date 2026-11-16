import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calendar/calendar_repository.dart';
import '../calendar/event.dart';
import '../work/shift.dart';
import '../work/work_repository.dart';
import 'phone_day.dart';
import 'phone_repository.dart';
import 'phone_usage.dart';

/// The first class, event or shift of a day.
typedef Commitment = ({String title, DateTime at});

/// The earliest event or shift that starts on [day].
Commitment? firstCommitment(
  DateTime day,
  Iterable<CalendarEvent> events,
  Iterable<Shift> shifts,
) {
  Commitment? first;
  void consider(String title, DateTime at) {
    if (first == null || at.isBefore(first!.at)) first = (title: title, at: at);
  }

  for (final CalendarEvent event in events) {
    if (!event.occursOn(day)) continue;
    final DateTime start = event.startsAt.toLocal();
    consider(
      event.title,
      DateTime(day.year, day.month, day.day, start.hour, start.minute),
    );
  }
  for (final Shift shift in shifts) {
    final DateTime s = shift.startsAt;
    if (s.year == day.year && s.month == day.month && s.day == day.day) {
      consider('Shift at ${shift.job}', s);
    }
  }
  return first;
}

/// The day whose morning is coming up: today in the small hours, otherwise
/// tomorrow.
DateTime nextMorning(DateTime now) => now.hour < 4
    ? DateTime(now.year, now.month, now.day)
    : DateTime(now.year, now.month, now.day + 1);

/// Hours of phone rest the plan line works back from.
const Duration plannedRest = Duration(hours: 8);

class PhoneState {
  const PhoneState({
    required this.hasAccess,
    required this.days,
    required this.selected,
    required this.apps,
    required this.nextMorning,
    required this.commitment,
    required this.androidAnswered,
  });

  final bool hasAccess;

  /// The last seven days, oldest first; a day Android has forgotten and that
  /// was never copied is missing.
  final List<PhoneDay> days;

  /// The day whose apps are listed.
  final DateTime selected;
  final List<AppUsage> apps;

  final DateTime nextMorning;
  final Commitment? commitment;

  /// False when Android refused to answer this time (e.g. the phone locked
  /// while reading); stored days are still shown.
  final bool androidAnswered;

  PhoneDay? dayFor(DateTime date) {
    for (final PhoneDay day in days) {
      if (day.date == date) return day;
    }
    return null;
  }

  /// Average screen time of the complete days shown; null with none.
  int? get averageMs {
    final List<PhoneDay> complete = <PhoneDay>[
      for (final PhoneDay day in days)
        if (day.complete) day,
    ];
    if (complete.isEmpty) return null;
    return complete.fold<int>(0, (int sum, PhoneDay d) => sum + d.screenOnMs) ~/
        complete.length;
  }
}

class PhoneController extends AsyncNotifier<PhoneState> {
  PhoneRepository get _repo => ref.read(phoneRepositoryProvider);

  DateTime? _selected;

  @override
  FutureOr<PhoneState> build() => _load();

  Future<PhoneState> _load() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final bool access = await ref.read(phoneUsageSourceProvider).hasAccess();
    final bool answered = access && await _repo.sync(now);
    final DateTime selected = _selected ?? today;
    final DateTime morning = nextMorning(now);
    final List<CalendarEvent> events = await ref
        .read(calendarRepositoryProvider)
        .getEvents();
    final List<Shift> shifts = await ref
        .read(workRepositoryProvider)
        .getShifts();
    return PhoneState(
      hasAccess: access,
      days: await _repo.getDays(
        DateTime(today.year, today.month, today.day - 6),
      ),
      selected: selected,
      apps: await _repo.getApps(selected),
      nextMorning: morning,
      commitment: firstCommitment(morning, events, shifts),
      androidAnswered: answered,
    );
  }

  /// Reads Android again, e.g. after the user returns from Settings.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> select(DateTime day) async {
    _selected = day;
    final PhoneState? current = state.value;
    if (current == null) return refresh();
    final List<AppUsage> apps = await _repo.getApps(day);
    state = AsyncData(
      PhoneState(
        hasAccess: current.hasAccess,
        days: current.days,
        selected: day,
        apps: apps,
        nextMorning: current.nextMorning,
        commitment: current.commitment,
        androidAnswered: current.androidAnswered,
      ),
    );
  }

  Future<void> openAccessSettings() =>
      ref.read(phoneUsageSourceProvider).openAccessSettings();
}

final AsyncNotifierProvider<PhoneController, PhoneState>
phoneControllerProvider = AsyncNotifierProvider<PhoneController, PhoneState>(
  PhoneController.new,
);
