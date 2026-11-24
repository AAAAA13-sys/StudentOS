import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/finance/finance_controller.dart';
import '../../features/finance/finance_repository.dart';
import '../../features/finance/ious_repository.dart';
import '../../features/insights/month_review.dart';
import '../../features/work/work_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'portable_export.dart';

/// Opens a modal sheet to export Transactions, Shifts, IOUs (`.csv`), or
/// Month in Review (`.md`) using [container] and [messenger] captured before
/// any drawer pop.
Future<void> showExportSheet(
  BuildContext rootContext,
  ProviderContainer container,
  ScaffoldMessengerState messenger,
) {
  return showModalBottomSheet<void>(
    context: rootContext,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => _ExportSheet(
      container: container,
      messenger: messenger,
    ),
  );
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({
    required this.container,
    required this.messenger,
  });

  final ProviderContainer container;
  final ScaffoldMessengerState messenger;

  String _activeMonth() =>
      container.read(financeControllerProvider).value?.month ??
      DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> _runExport(
    BuildContext sheetContext, {
    required Future<({String fileName, String content, String mimeType})>
    Function()
    build,
    required String successMessage,
  }) async {
    Navigator.pop(sheetContext);
    try {
      final ({String fileName, String content, String mimeType}) out =
          await build();
      final Uri? saved = await FilePicker.saveFile(
        fileName: out.fileName,
        bytes: utf8.encode(out.content),
        mimeType: out.mimeType,
      );
      if (saved != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not save export')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final String month = _activeMonth();
    final String stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Export CSV / summary',
                style: textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                'Portable files saved to your device',
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapMd,
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 56,
                      leading: const Icon(Icons.table_chart_outlined),
                      title: const Text('Transactions (current month .csv)'),
                      subtitle: Text('Cashflow for $month'),
                      onTap: () => _runExport(
                        context,
                        successMessage: 'Transactions CSV saved',
                        build: () async {
                          final items = await container
                              .read(financeRepositoryProvider)
                              .getTransactions(month: month);
                          return (
                            fileName: 'studentos-transactions-$month.csv',
                            content: exportTransactionsCsv(items),
                            mimeType: 'text/csv',
                          );
                        },
                      ),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 56,
                      leading: const Icon(Icons.table_rows_outlined),
                      title: const Text('Transactions (all months .csv)'),
                      subtitle: const Text('Complete cashflow history'),
                      onTap: () => _runExport(
                        context,
                        successMessage: 'All transactions CSV saved',
                        build: () async {
                          final items = await container
                              .read(financeRepositoryProvider)
                              .getTransactions();
                          return (
                            fileName: 'studentos-transactions-$stamp.csv',
                            content: exportTransactionsCsv(items),
                            mimeType: 'text/csv',
                          );
                        },
                      ),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 56,
                      leading: const Icon(Icons.work_outline_rounded),
                      title: const Text('Work shifts / DTR (.csv)'),
                      subtitle: const Text('Hours, breaks, rates and pay'),
                      onTap: () => _runExport(
                        context,
                        successMessage: 'Work shifts CSV saved',
                        build: () async {
                          final items = await container
                              .read(workRepositoryProvider)
                              .getShifts();
                          return (
                            fileName: 'studentos-shifts-$stamp.csv',
                            content: exportShiftsCsv(items),
                            mimeType: 'text/csv',
                          );
                        },
                      ),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 56,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: const Text('IOUs ledger (.csv)'),
                      subtitle: const Text('Open and settled splits'),
                      onTap: () => _runExport(
                        context,
                        successMessage: 'IOUs CSV saved',
                        build: () async {
                          final items = await container
                              .read(iousRepositoryProvider)
                              .getIous();
                          return (
                            fileName: 'studentos-ious-$stamp.csv',
                            content: exportIousCsv(items),
                            mimeType: 'text/csv',
                          );
                        },
                      ),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 56,
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Month in review (current month .md)'),
                      subtitle: Text('Markdown summary for $month'),
                      onTap: () => _runExport(
                        context,
                        successMessage: 'Month in review saved',
                        build: () async {
                          final MonthReview review = await container.read(
                            monthlyReviewProvider(month).future,
                          );
                          return (
                            fileName: 'studentos-review-$month.md',
                            content: exportMonthReviewMarkdown(review),
                            mimeType: 'text/markdown',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}
