import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How Ponpon feels in a given spot of the app.
enum PonponMood {
  /// Default: content, small smile.
  happy,

  /// Eyes shut, "z z": nothing scheduled, breaks, no alarms.
  sleepy,

  /// Eyes wide, mouth open: the alarm is ringing.
  yelling,

  /// Half-lidded and smirking: "still awake?", nothing found.
  smug,

  /// Looking down at a book: the focus timer.
  focused,
}

/// Ponpon, StudentOS's mascot: an orange tabby puspin (pusang Pinoy).
/// Drawn in code so it stays sharp at every size; the same painter renders
/// the PNGs the Android side uses (`tool/render_ponpon_test.dart`).
class Ponpon extends StatelessWidget {
  const Ponpon({this.mood = PonponMood.happy, this.size = 96, super.key});

  final PonponMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ponpon the cat',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: PonponPainter(mood)),
      ),
    );
  }
}

/// Colours of Ponpon. Fixed, not themed: Ponpon is orange in dark mode too.
abstract final class PonponColors {
  static const Color fur = Color(0xFFF4932B);
  static const Color stripe = Color(0xFFD5680F);
  static const Color cream = Color(0xFFFFE6C7);
  static const Color line = Color(0xFF3A2416);
  static const Color pink = Color(0xFFF29CA8);
  static const Color eye = Color(0xFF2A1A10);
  static const Color book = Color(0xFF9D71E8);
  static const Color bookPage = Color(0xFFF2E9FF);
}

class PonponPainter extends CustomPainter {
  const PonponPainter(this.mood);

  final PonponMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is drawn on a 100 x 100 grid.
    final double s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    final Paint fur = Paint()..color = PonponColors.fur;
    final Paint stripe = Paint()
      ..color = PonponColors.stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final Paint cream = Paint()..color = PonponColors.cream;
    final Paint pink = Paint()..color = PonponColors.pink;
    final Paint outline = Paint()
      ..color = PonponColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final Paint ink = Paint()..color = PonponColors.eye;

    void filled(Path p, Paint paint) {
      canvas.drawPath(p, paint);
      canvas.drawPath(p, outline);
    }

    // Tail, curling up on the right.
    final Path tail = Path()
      ..moveTo(66, 88)
      ..cubicTo(86, 90, 92, 74, 86, 60);
    canvas.drawPath(
      tail,
      Paint()
        ..color = PonponColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      tail,
      Paint()
        ..color = PonponColors.fur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(const Offset(87.5, 70), const Offset(91, 69), stripe);
    canvas.drawLine(const Offset(85, 80), const Offset(88.5, 81), stripe);

    // Body and chest.
    filled(Path()..addOval(const Rect.fromLTRB(28, 54, 72, 96)), fur);
    canvas.drawOval(const Rect.fromLTRB(39, 60, 61, 92), cream);
    canvas.drawLine(const Offset(30.5, 70), const Offset(35, 71), stripe);
    canvas.drawLine(const Offset(69.5, 70), const Offset(65, 71), stripe);

    // Ears, behind the head.
    Path ear(double x1, double tipX, double x2) => Path()
      ..moveTo(x1, 32)
      ..quadraticBezierTo(tipX - 1, 8, tipX, 5)
      ..quadraticBezierTo(tipX + 1, 8, x2, 20)
      ..close();
    filled(ear(21, 25, 44), fur);
    filled(ear(79, 75, 56), fur);
    canvas.drawPath(
      Path()
        ..moveTo(26, 26)
        ..lineTo(26.5, 11)
        ..lineTo(37, 21)
        ..close(),
      pink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(74, 26)
        ..lineTo(73.5, 11)
        ..lineTo(63, 21)
        ..close(),
      pink,
    );

    // Head.
    filled(
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(17, 16, 83, 64),
          const Radius.circular(24),
        ),
      ),
      fur,
    );
    // Tabby "M" on the forehead and stripes on the cheeks.
    canvas.drawLine(const Offset(50, 17.5), const Offset(50, 26), stripe);
    canvas.drawLine(const Offset(43, 18.5), const Offset(44.5, 24), stripe);
    canvas.drawLine(const Offset(57, 18.5), const Offset(55.5, 24), stripe);
    canvas.drawLine(const Offset(18.5, 40), const Offset(25, 41), stripe);
    canvas.drawLine(const Offset(19, 46), const Offset(25, 46), stripe);
    canvas.drawLine(const Offset(81.5, 40), const Offset(75, 41), stripe);
    canvas.drawLine(const Offset(81, 46), const Offset(75, 46), stripe);

    // Muzzle.
    canvas.drawOval(const Rect.fromLTRB(36, 43, 64, 60), cream);

    _face(canvas, outline, ink, pink);

    // Front paws, or the book for focus.
    if (mood == PonponMood.focused) {
      final Path book = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(33, 74, 67, 93),
            const Radius.circular(2.5),
          ),
        );
      filled(book, Paint()..color = PonponColors.book);
      canvas.drawRect(
        const Rect.fromLTRB(36, 76.5, 64, 90.5),
        Paint()..color = PonponColors.bookPage,
      );
      canvas.drawLine(const Offset(50, 76), const Offset(50, 91), outline);
      for (final double y in <double>[80, 84, 87.5]) {
        canvas.drawLine(
          Offset(39, y),
          Offset(47, y),
          Paint()
            ..color = PonponColors.book
            ..strokeWidth = 1.2,
        );
        canvas.drawLine(
          Offset(53, y),
          Offset(61, y),
          Paint()
            ..color = PonponColors.book
            ..strokeWidth = 1.2,
        );
      }
      filled(Path()..addOval(const Rect.fromLTRB(28, 80, 39, 89)), cream);
      filled(Path()..addOval(const Rect.fromLTRB(61, 80, 72, 89)), cream);
    } else if (mood == PonponMood.yelling) {
      // Paws up by the cheeks.
      filled(Path()..addOval(const Rect.fromLTRB(9, 48, 21, 59)), cream);
      filled(Path()..addOval(const Rect.fromLTRB(79, 48, 91, 59)), cream);
      filled(Path()..addOval(const Rect.fromLTRB(37, 89, 49, 97)), cream);
      filled(Path()..addOval(const Rect.fromLTRB(51, 89, 63, 97)), cream);
    } else {
      filled(Path()..addOval(const Rect.fromLTRB(36, 89, 48.5, 97)), cream);
      filled(Path()..addOval(const Rect.fromLTRB(51.5, 89, 64, 97)), cream);
    }

    _extras(canvas);
    canvas.restore();
  }

  void _face(Canvas canvas, Paint outline, Paint ink, Paint pink) {
    final Paint white = Paint()..color = Colors.white;
    final Paint blush = Paint()
      ..color = PonponColors.pink.withValues(alpha: 0.55);

    // Nose.
    final Path nose = Path()
      ..moveTo(46.5, 46)
      ..quadraticBezierTo(50, 44.5, 53.5, 46)
      ..quadraticBezierTo(51.5, 49.5, 50, 50)
      ..quadraticBezierTo(48.5, 49.5, 46.5, 46)
      ..close();

    switch (mood) {
      case PonponMood.happy:
        for (final double x in <double>[38, 62]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 36), width: 7, height: 8.5),
            ink,
          );
          canvas.drawCircle(Offset(x + 1.3, 34.3), 1.5, white);
        }
        canvas.drawOval(const Rect.fromLTRB(24, 45, 33, 50), blush);
        canvas.drawOval(const Rect.fromLTRB(67, 45, 76, 50), blush);
        canvas.drawPath(nose, pink);
        canvas.drawPath(
          Path()
            ..moveTo(44.5, 52)
            ..quadraticBezierTo(47.5, 55.5, 50, 51.5)
            ..quadraticBezierTo(52.5, 55.5, 55.5, 52),
          outline,
        );
      case PonponMood.sleepy:
        for (final double x in <double>[38, 62]) {
          canvas.drawPath(
            Path()
              ..moveTo(x - 5, 36)
              ..quadraticBezierTo(x, 40, x + 5, 36),
            outline,
          );
        }
        canvas.drawOval(const Rect.fromLTRB(24, 44, 33, 49), blush);
        canvas.drawOval(const Rect.fromLTRB(67, 44, 76, 49), blush);
        canvas.drawPath(nose, pink);
        canvas.drawPath(
          Path()
            ..moveTo(47.5, 53)
            ..quadraticBezierTo(50, 54.5, 52.5, 53),
          outline,
        );
      case PonponMood.yelling:
        for (final double x in <double>[37.5, 62.5]) {
          canvas.drawCircle(Offset(x, 34.5), 6.2, white);
          canvas.drawCircle(Offset(x, 34.5), 6.2, outline);
          canvas.drawCircle(Offset(x, 35), 2.3, ink);
        }
        canvas.drawPath(nose, pink);
        final Path mouth = Path()
          ..addOval(const Rect.fromLTRB(42.5, 50.5, 57.5, 62.5));
        canvas.drawPath(mouth, ink);
        canvas.drawOval(
          const Rect.fromLTRB(45.5, 56.5, 54.5, 62),
          Paint()..color = PonponColors.pink,
        );
        canvas.drawPath(mouth, outline);
      case PonponMood.smug:
        for (final double x in <double>[38, 62]) {
          // Half-closed: the lid is a flat line over the lower half.
          canvas.drawPath(
            Path()
              ..moveTo(x - 4, 36)
              ..arcToPoint(
                Offset(x + 4, 36),
                radius: const Radius.circular(4),
                clockwise: false,
              )
              ..close(),
            ink,
          );
          canvas.drawLine(Offset(x - 5, 35.5), Offset(x + 5, 35.5), outline);
        }
        // One brow up.
        canvas.drawPath(
          Path()
            ..moveTo(57, 27.5)
            ..quadraticBezierTo(62, 25, 67, 27.5),
          outline,
        );
        canvas.drawPath(nose, pink);
        canvas.drawPath(
          Path()
            ..moveTo(46, 53)
            ..quadraticBezierTo(51, 55, 56.5, 51),
          outline,
        );
      case PonponMood.focused:
        for (final double x in <double>[38, 62]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 38), width: 6.5, height: 6),
            ink,
          );
          canvas.drawPath(
            Path()
              ..moveTo(x - 5, 33.5)
              ..quadraticBezierTo(x, 31.5, x + 5, 33.5),
            outline,
          );
        }
        canvas.drawPath(nose, pink);
        canvas.drawLine(
          const Offset(47.5, 53),
          const Offset(52.5, 53),
          outline,
        );
    }

    // Whiskers.
    final Paint whisker = Paint()
      ..color = PonponColors.line.withValues(alpha: 0.55)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(35, 50), const Offset(25, 49), whisker);
    canvas.drawLine(const Offset(35, 53), const Offset(26, 54.5), whisker);
    canvas.drawLine(const Offset(65, 50), const Offset(75, 49), whisker);
    canvas.drawLine(const Offset(65, 53), const Offset(74, 54.5), whisker);
  }

  void _extras(Canvas canvas) {
    final Paint mark = Paint()
      ..color = PonponColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (mood) {
      case PonponMood.sleepy:
        void z(double x, double y, double w) => canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x + w, y)
            ..lineTo(x, y + w)
            ..lineTo(x + w, y + w),
          mark,
        );
        z(80, 14, 6);
        z(89, 4, 4.5);
      case PonponMood.yelling:
        canvas.drawLine(const Offset(6, 30), const Offset(12, 34), mark);
        canvas.drawLine(const Offset(4, 40), const Offset(11, 41), mark);
        canvas.drawLine(const Offset(94, 30), const Offset(88, 34), mark);
        canvas.drawLine(const Offset(96, 40), const Offset(89, 41), mark);
      case PonponMood.happy:
      case PonponMood.smug:
      case PonponMood.focused:
        break;
    }
  }

  @override
  bool shouldRepaint(PonponPainter oldDelegate) => oldDelegate.mood != mood;
}
