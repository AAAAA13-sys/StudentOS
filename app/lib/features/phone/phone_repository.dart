import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'phone_day.dart';
import 'phone_usage.dart';

class PhoneRepository {
  const PhoneRepository(this._db, this._source);

  final AppDatabase _db;
  final PhoneUsageSource _source;

  /// Android keeps detailed usage for only a few days, so recent days are
  /// copied in whenever the app opens.
  static const int daysToCopy = 7;

  static String dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Copies the last [daysToCopy] days from Android, skipping days already
  /// stored as complete and days Android has forgotten. Returns false when
  /// Android would not answer at all.
  Future<bool> sync(DateTime now) async {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final Set<String> done = <String>{
      for (final PhoneDayRow row in await (_db.select(
        _db.phoneDayRows,
      )..where((t) => t.complete.equals(true))).get())
        row.date,
    };
    for (int back = daysToCopy - 1; back >= 0; back--) {
      final DateTime day = DateTime(today.year, today.month, today.day - back);
      final String key = dateKey(day);
      if (done.contains(key)) continue;
      final UsageRange? usage = await _source.query(
        day,
        DateTime(day.year, day.month, day.day + 1),
      );
      if (usage == null) return false;
      // A past day with no events at all has been forgotten by Android.
      if (back > 0 && usage.eventCount == 0) continue;
      final (DateTime windowStart, DateTime windowEnd) = restWindowFor(day);
      final UsageRange? rest = await _source.query(windowStart, windowEnd);
      final PhoneDay summary = phoneDayFrom(
        day: day,
        usage: usage,
        rest: rest,
        now: now,
      );
      await _store(key, summary, usage.apps);
    }
    return true;
  }

  Future<void> _store(String key, PhoneDay day, List<AppUsage> apps) {
    return _db.transaction(() async {
      await _db
          .into(_db.phoneDayRows)
          .insertOnConflictUpdate(
            PhoneDayRowsCompanion.insert(
              date: key,
              screenOnMs: day.screenOnMs,
              unlocks: day.unlocks,
              firstPickup: Value(day.firstPickup),
              restStart: Value(day.restStart),
              restEnd: Value(day.restEnd),
              complete: Value(day.complete),
            ),
          );
      await (_db.delete(
        _db.phoneAppDayRows,
      )..where((t) => t.date.equals(key))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.phoneAppDayRows, <PhoneAppDayRowsCompanion>[
          for (final AppUsage app in apps)
            PhoneAppDayRowsCompanion.insert(
              date: key,
              package: app.package,
              label: app.label,
              foregroundMs: app.ms,
            ),
        ]);
      });
    });
  }

  /// Stored days from [from] onward, earliest first.
  Future<List<PhoneDay>> getDays(DateTime from) async {
    final List<PhoneDayRow> rows =
        await (_db.select(_db.phoneDayRows)
              ..where((t) => t.date.isBiggerOrEqualValue(dateKey(from)))
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();
    return <PhoneDay>[
      for (final PhoneDayRow row in rows)
        PhoneDay(
          date: DateTime.parse(row.date),
          screenOnMs: row.screenOnMs,
          unlocks: row.unlocks,
          firstPickup: row.firstPickup,
          restStart: row.restStart,
          restEnd: row.restEnd,
          complete: row.complete,
        ),
    ];
  }

  /// The apps used on [day], most time first.
  Future<List<AppUsage>> getApps(DateTime day) async {
    final List<PhoneAppDayRow> rows =
        await (_db.select(_db.phoneAppDayRows)
              ..where((t) => t.date.equals(dateKey(day)))
              ..orderBy([(t) => OrderingTerm.desc(t.foregroundMs)]))
            .get();
    return <AppUsage>[
      for (final PhoneAppDayRow row in rows)
        AppUsage(package: row.package, label: row.label, ms: row.foregroundMs),
    ];
  }
}

final Provider<PhoneRepository> phoneRepositoryProvider =
    Provider<PhoneRepository>(
      (ref) => PhoneRepository(
        ref.watch(appDatabaseProvider),
        ref.watch(phoneUsageSourceProvider),
      ),
    );
