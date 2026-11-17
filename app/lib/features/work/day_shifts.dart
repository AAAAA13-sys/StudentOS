import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'shift.dart';
import 'work_controller.dart';

/// The work shifts that start on [day], one outlined row each, for the
/// calendar's day list. Takes no space on a day without shifts.
class DayShifts extends ConsumerWidget {
  const DayShifts({required this.day, super.key});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Shift> shifts = inDateOrder(<Shift>[
      for (final Shift shift
          in ref.watch(workControllerProvider).value ?? const <Shift>[])
        if (shift.startsAt.year == day.year &&
            shift.startsAt.month == day.month &&
            shift.startsAt.day == day.day)
          shift,
    ]);
    if (shifts.isEmpty) return const SizedBox.shrink();

    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final DateFormat time = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: <Widget>[
          for (final Shift shift in shifts)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.large,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.work_outline_rounded,
                    size: AppSizes.iconSm,
                    color: colors.onSurfaceVariant,
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Shift at ${shift.job}',
                          style: textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${time.format(shift.startsAt)} – '
                          '${time.format(shift.endsAt)} · '
                          '${formatHours(shift.paidMinutes)} hrs',
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
              ),
            ),
        ],
      ),
    );
  }
}
