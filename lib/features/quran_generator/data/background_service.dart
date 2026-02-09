import 'dart:io';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../../core/errors/exceptions.dart';

class BackgroundService {
  Future<File> createGradientBackground({
    required Directory outputDir,
    required int width,
    required int height,
    required List<ui.Color> colors,
    String fileName = 'gradient_bg.png',
  }) async {
    if (colors.length < 2) {
      throw ProcessingException('Gradient requires at least two colors');
    }

    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      final t = y / (height - 1);
      final color = _lerpColor(colors.first, colors.last, t);
      for (var x = 0; x < width; x++) {
        image.setPixelRgba(
          x,
          y,
          color.r,
          color.g,
          color.b,
          color.a,
        );
      }
    }

    final outputPath = p.join(outputDir.path, fileName);
    final file = File(outputPath);
    await file.writeAsBytes(img.encodePng(image));
    return file;
  }

  img.Color _lerpColor(ui.Color a, ui.Color b, double t) {
    int lerp(int start, int end) => start + ((end - start) * t).round();
    return img.ColorRgba8(
      lerp((a.r * 255).round(), (b.r * 255).round()),
      lerp((a.g * 255).round(), (b.g * 255).round()),
      lerp((a.b * 255).round(), (b.b * 255).round()),
      lerp((a.a * 255).round(), (b.a * 255).round()),
    );
  }
}
