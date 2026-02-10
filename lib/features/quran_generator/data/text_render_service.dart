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
    required String reciterName,
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
      if (filter.showAyahNumber) {
        if (infoLine.isNotEmpty) infoLine += ' - ';
        infoLine += 'آية $currentAyahNumber';
      }
      if (filter.showReciterName) {
        if (infoLine.isNotEmpty) infoLine += ' - ';
        infoLine += reciterName;
      }

      final fileName = 'ayah_$i.png';
      final file = await _renderSingleImage(
        text: displayText,
        infoLine: infoLine,
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
      infoLine: '',
      filter: filter,
      outputDir: outputDir,
      width: width,
      height: height,
      fileName: 'ayah_text.png',
    );
  }

  Future<File> _renderSingleImage({
    required String text,
    required String infoLine,
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
          height: 1.0 + (filter.lineSpacing / 50.0), // Higher base spacing
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
        height: 1.0 + (filter.lineSpacing / 50.0), // Higher base spacing
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
        : (height - fillParagraph.height - 250); // Moved slightly up to make room for footer

    canvas.drawParagraph(fillParagraph, Offset(x, y));

    // Draw Footer (infoLine) at the bottom
    if (infoLine.isNotEmpty) {
      final footerBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          fontSize: (filter.fontSize * 0.4).clamp(14, 28),
          fontFamily: filter.fontFamily,
          height: 1.2, // Improved alignment for footer
        ),
      )..pushStyle(ui.TextStyle(
          color: filter.textColor.withAlpha(200),
          fontWeight: FontWeight.bold,
        ))
       ..addText(infoLine);

      final footerParagraph = footerBuilder.build();
      footerParagraph.layout(ui.ParagraphConstraints(width: width.toDouble() * 0.9));
      
      final footerX = (width - footerParagraph.width) / 2;
      final footerY = height - footerParagraph.height - 60; // Fixed offset from bottom
      
      // Draw a subtle shadow/glow for footer
      canvas.drawRect(
        Rect.fromLTWH(footerX - 10, footerY - 5, footerParagraph.width + 20, footerParagraph.height + 10),
        Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      canvas.drawParagraph(footerParagraph, Offset(footerX, footerY));
    }

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
