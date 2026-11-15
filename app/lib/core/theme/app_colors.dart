import 'package:flutter/material.dart';

/// Raw colour tokens from DESIGN.md. Screens must not use these directly;
/// read colours from `Theme.of(context).colorScheme` or [ModuleColors].
abstract final class AppColors {
  static const Color cyan700 = Color(0xFF0E7490);
  static const Color cyan800 = Color(0xFF155E75);
  static const Color cyan900 = Color(0xFF164E63);
  static const Color cyan950 = Color(0xFF083344);
  static const Color cyan300 = Color(0xFF67E8F9);
  static const Color cyan100 = Color(0xFFCFFAFE);

  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color emerald950 = Color(0xFF022C22);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald100 = Color(0xFFD1FAE5);

  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber950 = Color(0xFF451A03);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber100 = Color(0xFFFEF3C7);

  static const Color red700 = Color(0xFFB91C1C);
  static const Color red900 = Color(0xFF7F1D1D);
  static const Color red950 = Color(0xFF450A0A);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red100 = Color(0xFFFEE2E2);

  static const Color white = Color(0xFFFFFFFF);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate150 = Color(0xFFEEF2F6);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate250 = Color(0xFFDCE3EC);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate750 = Color(0xFF263449);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate850 = Color(0xFF131C2E);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF0B1220);
}

/// Per-module accents and semantic money colours.
///
/// Usage: `Theme.of(context).extension<ModuleColors>()!.finance` or the
/// shorthand `context.moduleColors.finance` from `app_theme.dart`.
@immutable
class ModuleColors extends ThemeExtension<ModuleColors> {
  const ModuleColors({
    required this.calendar,
    required this.finance,
    required this.notes,
    required this.income,
    required this.expense,
  });

  final Color calendar;
  final Color finance;
  final Color notes;
  final Color income;
  final Color expense;

  static const ModuleColors light = ModuleColors(
    calendar: AppColors.cyan700,
    finance: AppColors.emerald700,
    notes: AppColors.amber700,
    income: AppColors.emerald700,
    expense: AppColors.red700,
  );

  static const ModuleColors dark = ModuleColors(
    calendar: AppColors.cyan300,
    finance: AppColors.emerald300,
    notes: AppColors.amber300,
    income: AppColors.emerald300,
    expense: AppColors.red300,
  );

  @override
  ModuleColors copyWith({
    Color? calendar,
    Color? finance,
    Color? notes,
    Color? income,
    Color? expense,
  }) {
    return ModuleColors(
      calendar: calendar ?? this.calendar,
      finance: finance ?? this.finance,
      notes: notes ?? this.notes,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }

  @override
  ModuleColors lerp(ThemeExtension<ModuleColors>? other, double t) {
    if (other is! ModuleColors) {
      return this;
    }
    return ModuleColors(
      calendar: Color.lerp(calendar, other.calendar, t)!,
      finance: Color.lerp(finance, other.finance, t)!,
      notes: Color.lerp(notes, other.notes, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
    );
  }
}
