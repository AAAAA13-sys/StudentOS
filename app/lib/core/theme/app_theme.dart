import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Builds the light and dark Material 3 themes from the DESIGN.md tokens.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme, ModuleColors.light);

  static ThemeData get dark => _build(_darkScheme, ModuleColors.dark);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(seedColor: AppColors.cyan700).copyWith(
        primary: AppColors.cyan700,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.cyan100,
        onPrimaryContainer: AppColors.cyan900,
        secondary: AppColors.emerald700,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.emerald100,
        onSecondaryContainer: AppColors.emerald900,
        tertiary: AppColors.amber700,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.amber100,
        onTertiaryContainer: AppColors.amber900,
        error: AppColors.red700,
        onError: AppColors.white,
        errorContainer: AppColors.red100,
        onErrorContainer: AppColors.red900,
        surface: AppColors.slate50,
        onSurface: AppColors.slate900,
        onSurfaceVariant: AppColors.slate600,
        surfaceContainerLowest: AppColors.white,
        surfaceContainerLow: AppColors.slate100,
        surfaceContainer: AppColors.slate150,
        surfaceContainerHigh: AppColors.slate200,
        surfaceContainerHighest: AppColors.slate250,
        outline: AppColors.slate500,
        outlineVariant: AppColors.slate300,
        inverseSurface: AppColors.slate800,
        onInverseSurface: AppColors.slate100,
        inversePrimary: AppColors.cyan300,
        surfaceTint: Colors.transparent,
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.cyan700,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.cyan300,
        onPrimary: AppColors.cyan950,
        primaryContainer: AppColors.cyan800,
        onPrimaryContainer: AppColors.cyan100,
        secondary: AppColors.emerald300,
        onSecondary: AppColors.emerald950,
        secondaryContainer: AppColors.emerald800,
        onSecondaryContainer: AppColors.emerald100,
        tertiary: AppColors.amber300,
        onTertiary: AppColors.amber950,
        tertiaryContainer: AppColors.amber800,
        onTertiaryContainer: AppColors.amber100,
        error: AppColors.red300,
        onError: AppColors.red950,
        errorContainer: AppColors.red900,
        onErrorContainer: AppColors.red100,
        surface: AppColors.slate900,
        onSurface: AppColors.slate100,
        onSurfaceVariant: AppColors.slate300,
        surfaceContainerLowest: AppColors.slate950,
        surfaceContainerLow: AppColors.slate850,
        surfaceContainer: AppColors.slate800,
        surfaceContainerHigh: AppColors.slate750,
        surfaceContainerHighest: AppColors.slate700,
        outline: AppColors.slate500,
        outlineVariant: AppColors.slate700,
        inverseSurface: AppColors.slate100,
        onInverseSurface: AppColors.slate900,
        inversePrimary: AppColors.cyan700,
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
      extensions: <ThemeExtension<dynamic>>[moduleColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSizes.iconMd,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButtonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minButtonSize,
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: scheme.outline),
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
          textStyle: textTheme.labelLarge,
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
        highlightElevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        errorMaxLines: 3,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
        side: BorderSide(color: scheme.outlineVariant),
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
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.extraLarge,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 3,
        showDragHandle: true,
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
      displaySmall: style(36, 44, FontWeight.w700),
      headlineLarge: style(32, 40, FontWeight.w700),
      headlineMedium: style(28, 36, FontWeight.w700),
      headlineSmall: style(24, 32, FontWeight.w600),
      titleLarge: style(20, 28, FontWeight.w600),
      titleMedium: style(16, 24, FontWeight.w600, 0.1),
      titleSmall: style(14, 20, FontWeight.w600, 0.1),
      bodyLarge: style(16, 24, FontWeight.w400, 0.2),
      bodyMedium: style(14, 20, FontWeight.w400, 0.2),
      bodySmall: style(12, 16, FontWeight.w400, 0.3),
      labelLarge: style(14, 20, FontWeight.w600, 0.1),
      labelMedium: style(12, 16, FontWeight.w500, 0.4),
      labelSmall: style(11, 16, FontWeight.w500, 0.4),
    );
  }
}

/// Shorthand accessors so screens never build styles by hand.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;

  ModuleColors get moduleColors => Theme.of(this).extension<ModuleColors>()!;
}
