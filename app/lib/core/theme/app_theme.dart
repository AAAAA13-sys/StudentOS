import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Builds the light and dark Material 3 themes following DESIGN_SYSTEM.md.
/// Implements the Anti-Slop "Hint of Lavender" aesthetic with high-craft hairlines.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme, ModuleColors.light);

  static ThemeData get dark => _build(_darkScheme, ModuleColors.dark);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(seedColor: AppColors.vibrantViolet).copyWith(
        primary: AppColors.vibrantViolet,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.lightLilac,
        onPrimaryContainer: AppColors.midnightIndigo,
        secondary: AppColors.mediumLavender,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.paleLavenderWhite,
        onSecondaryContainer: AppColors.darkPurple,
        tertiary: AppColors.amber700,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.amber100,
        onTertiaryContainer: AppColors.amber900,
        error: AppColors.red700,
        onError: AppColors.white,
        errorContainer: AppColors.red100,
        onErrorContainer: AppColors.red900,
        surface: AppColors.paleLavenderWhite,
        onSurface: AppColors.midnightIndigo,
        onSurfaceVariant: AppColors.darkPurple,
        surfaceContainerLowest: AppColors.white,
        surfaceContainerLow: AppColors.paleLavenderWhite,
        surfaceContainer: const Color(0xFFEADBFF),
        surfaceContainerHigh: const Color(0xFFE2D1FF),
        surfaceContainerHighest: AppColors.lightLilac,
        outline: AppColors.mediumLavender,
        outlineVariant: AppColors.hairlineLight,
        inverseSurface: AppColors.midnightIndigo,
        onInverseSurface: AppColors.paleLavenderWhite,
        inversePrimary: AppColors.lightLilac,
        surfaceTint: Colors.transparent,
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.vibrantViolet,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.lightLilac,
        onPrimary: AppColors.midnightIndigo,
        primaryContainer: AppColors.darkPurple,
        onPrimaryContainer: AppColors.lightLilac,
        secondary: AppColors.mediumLavender,
        onSecondary: AppColors.midnightIndigo,
        secondaryContainer: AppColors.darkPurple,
        onSecondaryContainer: AppColors.paleLavenderWhite,
        tertiary: AppColors.amber300,
        onTertiary: AppColors.amber950,
        tertiaryContainer: AppColors.amber800,
        onTertiaryContainer: AppColors.amber100,
        error: AppColors.red300,
        onError: AppColors.red950,
        errorContainer: AppColors.red900,
        onErrorContainer: AppColors.red100,
        surface: AppColors.midnightIndigo,
        onSurface: AppColors.paleLavenderWhite,
        onSurfaceVariant: AppColors.lightLilac,
        surfaceContainerLowest: AppColors.midnightIndigo,
        surfaceContainerLow: AppColors.darkPurple,
        surfaceContainer: const Color(0xFF1E103E),
        surfaceContainerHigh: const Color(0xFF2B1854),
        surfaceContainerHighest: const Color(0xFF3B2070),
        outline: AppColors.mediumLavender,
        outlineVariant: AppColors.hairlineDark,
        inverseSurface: AppColors.paleLavenderWhite,
        onInverseSurface: AppColors.midnightIndigo,
        inversePrimary: AppColors.vibrantViolet,
        surfaceTint: Colors.transparent,
      );

  static ThemeData _build(ColorScheme scheme, ModuleColors moduleColors) {
    final TextTheme textTheme = _textTheme(scheme);
    const Size minButtonSize = Size(64, AppSizes.buttonHeight);
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
    );
    const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: AppRadius.medium,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashColor: scheme.primary.withValues(alpha: 0.08),
      highlightColor: scheme.primary.withValues(alpha: 0.04),
      extensions: <ThemeExtension<dynamic>>[moduleColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSizes.iconMd,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: scheme.outlineVariant, width: 1.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: minButtonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minButtonSize,
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: scheme.outlineVariant, width: 1.0),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
          shape: buttonShape,
          textStyle: textTheme.labelLarge?.copyWith(color: scheme.primary),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: inputBorder(scheme.outlineVariant),
        enabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, 1.5),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.5),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        errorMaxLines: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        side: BorderSide(color: scheme.outlineVariant, width: 1.0),
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.extraLarge),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 3,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
      ),
    );
  }

  /// Material 3 type scale on the platform font (Roboto on Android).
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle style(
      double size,
      double height,
      FontWeight weight, [
      double spacing = 0,
    ]) {
      return TextStyle(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: spacing,
        color: scheme.onSurface,
      );
    }

    return TextTheme(
      displaySmall: style(36, 44, FontWeight.w700, -0.5),
      headlineLarge: style(32, 40, FontWeight.w700, -0.4),
      headlineMedium: style(28, 36, FontWeight.w700, -0.3),
      headlineSmall: style(24, 32, FontWeight.w600, -0.2),
      titleLarge: style(20, 28, FontWeight.w600, 0),
      titleMedium: style(16, 24, FontWeight.w600, 0.1),
      titleSmall: style(14, 20, FontWeight.w600, 0.1),
      bodyLarge: style(16, 24, FontWeight.w400, 0.15),
      bodyMedium: style(14, 20, FontWeight.w400, 0.2),
      bodySmall: style(12, 16, FontWeight.w400, 0.3),
      labelLarge: style(14, 20, FontWeight.w600, 0.1),
      labelMedium: style(12, 16, FontWeight.w500, 0.4),
      labelSmall: style(11, 16, FontWeight.w500, 0.5),
    );
  }
}

/// Shorthand accessors so screens never build styles by hand.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;

  ModuleColors get moduleColors => Theme.of(this).extension<ModuleColors>()!;
}
