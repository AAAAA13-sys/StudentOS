import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';

/// How the Schedule shows time: the month grid or a seven-day list.
enum ScheduleView { month, week }

const String _key = 'schedule_view';

/// The Schedule's month/week choice, kept in the `settings` table so it
/// survives a restart. Starts on month and switches once the stored value is
/// read, unless the user already chose in the meantime.
class ScheduleViewController extends Notifier<ScheduleView> {
  bool _chosen = false;

  @override
  ScheduleView build() {
    unawaited(_load());
    return ScheduleView.month;
  }

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> _load() async {
    try {
      final SettingRow? row = await (_db.select(
        _db.settingRows,
      )..where((t) => t.key.equals(_key))).getSingleOrNull();
      if (!ref.mounted || _chosen) return;
      if (row?.value == 'week') state = ScheduleView.week;
    } catch (_) {
      // Keep the default when the setting cannot be read.
    }
  }

  Future<void> show(ScheduleView view) async {
    _chosen = true;
    state = view;
    try {
      await _db
          .into(_db.settingRows)
          .insertOnConflictUpdate(
            SettingRowsCompanion.insert(key: _key, value: view.name),
          );
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

final NotifierProvider<ScheduleViewController, ScheduleView>
scheduleViewProvider = NotifierProvider<ScheduleViewController, ScheduleView>(
  ScheduleViewController.new,
);
