import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// A small outlined status pill ("Done", "Exam · Tomorrow") above a title.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pill,
        border: Border.all(color: border.withValues(alpha: 0.3), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: foreground),
          AppSpacing.gapXs,
          Flexible(
            child: Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
                fontFeatures: _tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
