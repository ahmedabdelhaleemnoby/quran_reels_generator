import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/errors/exceptions.dart';
import '../domain/filter_theme.dart';

class TextRenderService {
  Future<List<File>> renderAyahImages({
    required List<String> ayahs,
    required FilterTheme filter,
    required String surahName,
    required int fromAyah,
    required Directory outputDir,
    required int width,
    required int height,
  }) async {
    final files = <File>[];
    for (var i = 0; i < ayahs.length; i++) {
      var displayText = ayahs[i];
      final currentAyahNumber = fromAyah + i;
      
      var infoLine = '';
      if (filter.showSurahName) infoLine += surahName;
      if (filter.showAyahNumber) infoLine += ' - آية $currentAyahNumber';
      
      if (infoLine.isNotEmpty) {
        displayText = '$displayText\n\n($infoLine)';
      }

      final fileName = 'ayah_$i.png';
      final file = await _renderSingleImage(
        text: displayText,
        filter: filter,
        outputDir: outputDir,
        width: width,
        height: height,
        fileName: fileName,
      );
      files.add(file);
    }
    return files;
  }

  Future<File> renderTextImage({
    required String text,
    required FilterTheme filter,
    required Directory outputDir,
    required int width,
    required int height,
  }) async {
    return _renderSingleImage(
      text: text,
      filter: filter,
      outputDir: outputDir,
      width: width,
      height: height,
      fileName: 'ayah_text.png',
    );
  }

  Future<File> _renderSingleImage({
    required String text,
    required FilterTheme filter,
    required Directory outputDir,
    required int width,
    required int height,
    required String fileName,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // Draw stroke if needed
    if (filter.strokeWidth > 0) {
      final strokeBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          fontSize: filter.fontSize,
          fontFamily: filter.fontFamily,
          height: filter.lineSpacing / filter.fontSize,
        ),
      )..pushStyle(ui.TextStyle(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = filter.strokeWidth
            ..color = filter.strokeColor,
          letterSpacing: filter.letterSpacing,
        ))
       ..addText(text);

      final strokeParagraph = strokeBuilder.build();
      strokeParagraph.layout(ui.ParagraphConstraints(width: width.toDouble() * 0.9));
      
      final strokeX = (width - strokeParagraph.width) / 2;
      final strokeY = filter.textPosition == TextPosition.center
          ? (height - strokeParagraph.height) / 2
          : (height - strokeParagraph.height - 200);
          
      canvas.drawParagraph(strokeParagraph, Offset(strokeX, strokeY));
    }

    // Draw fill text
    final fillBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        fontSize: filter.fontSize,
        fontFamily: filter.fontFamily,
        height: filter.lineSpacing / filter.fontSize,
      ),
    )..pushStyle(ui.TextStyle(
        color: filter.textColor,
        letterSpacing: filter.letterSpacing,
      ))
     ..addText(text);

    final fillParagraph = fillBuilder.build();
    fillParagraph.layout(ui.ParagraphConstraints(width: width.toDouble() * 0.9));

    final x = (width - fillParagraph.width) / 2;
    final y = filter.textPosition == TextPosition.center
        ? (height - fillParagraph.height) / 2
        : (height - fillParagraph.height - 200);

    canvas.drawParagraph(fillParagraph, Offset(x, y));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (pngBytes == null) {
      throw ProcessingException('Failed to encode text image');
    }

    final outputPath = p.join(outputDir.path, fileName);
    final file = File(outputPath);
    await file.writeAsBytes(pngBytes.buffer.asUint8List());

    return file;
  }
}
