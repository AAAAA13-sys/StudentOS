import 'package:flutter/widgets.dart';

/// 4dp spacing scale from DESIGN.md. Never hardcode paddings in screens.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard horizontal + vertical padding of a screen body.
  static const EdgeInsets screen = EdgeInsets.all(lg);

  /// Standard inner padding of a card or list tile container.
  static const EdgeInsets card = EdgeInsets.all(lg);

  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
}

/// Corner radii from DESIGN.md.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(xl));
}

/// Sizes that keep the UI accessible.
abstract final class AppSizes {
  /// Minimum touch target (Material / WCAG 2.5.5).
  static const double minTouchTarget = 48;

  /// Height of primary and secondary buttons.
  static const double buttonHeight = 52;

  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconXl = 64;

  /// Forms and reading content never grow wider than this on tablets.
  static const double maxContentWidth = 560;
}

/// Motion durations. Keep animations between 150 and 300 ms.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration snackBar = Duration(seconds: 4);
}
