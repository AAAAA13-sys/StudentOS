// Renders Ponpon to PNG files for the Android side (alarm screen, widgets)
// and a preview sheet. Not part of the test suite (it lives in tool/).
//
//   flutter test tool/render_ponpon_test.dart
//
// Output: build/ponpon/ponpon_<mood>.png (512 x 512, transparent).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/widgets/ponpon.dart';

void main() {
  test('render Ponpon', () async {
    final Directory out = Directory('build/ponpon')
      ..createSync(recursive: true);
    const int px = 512;
    for (final PonponMood mood in PonponMood.values) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      PonponPainter(mood).paint(canvas, const ui.Size(512, 512));
      final ui.Image image = await recorder.endRecording().toImage(px, px);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/ponpon_${mood.name}.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    }
  });
}
