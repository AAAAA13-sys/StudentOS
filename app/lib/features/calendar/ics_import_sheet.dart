import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'event.dart';
import 'ics_import.dart';

/// Lets the user pick an `.ics` file and returns its text, or null when they
/// cancel. A provider so tests can supply a file without the system picker.
final Provider<Future<String?> Function()> icsFilePickerProvider =
    Provider<Future<String?> Function()>(
      (Ref ref) => () async {
        final PlatformFile? file = await FilePicker.pickFile();
        if (file == null) return null;
        return utf8.decode(await file.readAsBytes(), allowMalformed: true);
      },
    );

/// What the import preview shows and, when confirmed, saves.
class IcsPreview {
  const IcsPreview({
    required this.fresh,
    required this.found,
    required this.duplicates,
    required this.skipped,
    required this.warnings,
  });

  /// Events not already in the calendar.
  final List<CalendarEvent> fresh;
  final int found;
  final int duplicates;
  final int skipped;
  final List<String> warnings;
}

/// Splits [result] into new events and ones already in [existing] (same
/// title and start), also dropping repeats inside the file itself.
IcsPreview buildIcsPreview(
  IcsImportResult result,
  List<CalendarEvent> existing,
) {
  String key(CalendarEvent e) =>
      '${e.title.trim().toLowerCase()}|${e.startsAt.millisecondsSinceEpoch}';
  final Set<String> seen = <String>{
    for (final CalendarEvent e in existing) key(e),
  };
  final List<CalendarEvent> fresh = <CalendarEvent>[];
  int duplicates = 0;
  for (final CalendarEvent e in result.events) {
    if (seen.add(key(e))) {
      fresh.add(e);
    } else {
      duplicates++;
    }
  }
  return IcsPreview(
    fresh: fresh,
    found: result.events.length,
    duplicates: duplicates,
    skipped: result.skipped,
    warnings: result.warnings,
  );
}

/// Shows the preview; true when the user taps Import.
Future<bool> showIcsImportSheet(
  BuildContext context,
  IcsPreview preview,
) async {
  final bool? ok = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => _IcsImportSheet(preview: preview),
  );
  return ok ?? false;
}

class _IcsImportSheet extends StatelessWidget {
  const _IcsImportSheet({required this.preview});

  final IcsPreview preview;

  static const int _maxRows = 5;

  static String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final List<String> notes = <String>[
      if (preview.duplicates > 0)
        '${_plural(preview.duplicates, 'event')} already in your calendar '
            '(skipped)',
      if (preview.skipped > 0)
        '${_plural(preview.skipped, 'event')} not supported (skipped)',
      ...preview.warnings,
    ];
    final List<CalendarEvent> shown =
        (List<CalendarEvent>.of(preview.fresh)
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt)))
            .take(_maxRows)
            .toList();
    final int more = preview.fresh.length - shown.length;
    final MaterialLocalizations l10n = MaterialLocalizations.of(context);

    String when(CalendarEvent e) {
      final String day = DateFormat('EEE, MMM d, yyyy').format(e.startsAt);
      final bool allDay =
          e.durationMinutes == 1440 &&
          e.startsAt.hour == 0 &&
          e.startsAt.minute == 0;
      final String time = allDay
          ? 'All day'
          : l10n.formatTimeOfDay(TimeOfDay.fromDateTime(e.startsAt));
      final String repeat = e.recurrence == 'none'
          ? ''
          : ' · repeats ${e.recurrence}';
      return '$day · $time$repeat';
    }

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${_plural(preview.found, 'event')} found',
              style: textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              preview.fresh.isEmpty
                  ? 'Nothing new to import.'
                  : 'Review them, then import into your calendar.',
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (shown.isNotEmpty) ...<Widget>[
              AppSpacing.gapMd,
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant, width: 0.75),
                  borderRadius: AppRadius.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < shown.length; i++) ...<Widget>[
                      if (i > 0)
                        Divider(
                          height: 0.75,
                          thickness: 0.75,
                          color: colors.outlineVariant,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              shown[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              when(shown[i]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'and $more more',
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            if (notes.isNotEmpty) ...<Widget>[
              AppSpacing.gapMd,
              for (final String note in notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    note,
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            AppSpacing.gapXl,
            SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton(
                onPressed: preview.fresh.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: Text(
                  preview.fresh.isEmpty
                      ? 'Import'
                      : 'Import ${preview.fresh.length}',
                ),
              ),
            ),
            AppSpacing.gapLg,
          ],
        ),
      ),
    );
  }
}
