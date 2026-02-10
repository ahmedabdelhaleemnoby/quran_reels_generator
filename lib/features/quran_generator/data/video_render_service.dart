import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/errors/exceptions.dart';
import '../domain/filter_theme.dart';
import 'command_runner.dart';

class VideoRenderService {
  VideoRenderService({CommandRunner? runner})
      : _runner = runner ?? CommandRunner();

  final CommandRunner _runner;

  Future<File> renderVideo({
    required FilterTheme filter,
    required File audioFile,
    required List<File> textImages,
    required List<double> durations,
    required Directory outputDir,
    List<File>? backgroundFiles,
    required int width,
    required int height,
    int fps = 30,
  }) async {
    final outputPath = p.join(
      outputDir.path,
      'quran_reel_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    final rawDuration = durations.fold(0.0, (sum, d) => sum + d);
    final totalDuration = rawDuration > 60.0 ? 60.0 : rawDuration;
    final args = <String>[];

    // Background Inputs
    final bool hasFiles = backgroundFiles != null && backgroundFiles.isNotEmpty;
    final isVideoType = filter.backgroundType == BackgroundType.videoFile;

    if (filter.backgroundType == BackgroundType.solidColor || !hasFiles) {
      // Use solid color as fallback if no files are provided, even if type is image/video
      final color = filter.backgroundColor ?? const Color(0xFF000000);
      args.addAll([
        '-f', 'lavfi',
        '-i', 'color=c=${_colorToHex(color)}:s=${width}x$height:r=$fps:d=$totalDuration',
      ]);
    } else if (isVideoType) {
      args.addAll([
        '-stream_loop', '-1',
        '-i', backgroundFiles.first.path,
      ]);
    } else {
      // Image or Gradient (Slideshow or single)
      for (final file in backgroundFiles) {
        args.addAll(['-loop', '1', '-i', file.path]);
      }
    }

    // Text Image Inputs
    final bgInputCount = (filter.backgroundType == BackgroundType.solidColor || !hasFiles || isVideoType) 
        ? 1 : backgroundFiles.length;
    
    for (final image in textImages) {
      args.addAll(['-i', image.path]);
    }

    // Audio Input
    args.addAll(['-i', audioFile.path]);

    final audioInputIdx = bgInputCount + textImages.length;

    args.addAll([
      '-filter_complex',
      _buildFilterComplex(filter, bgInputCount, textImages.length, durations, width, height),
      '-map', '[v_out]',
      '-map', '$audioInputIdx:a',
      '-t', totalDuration.toStringAsFixed(2),
      '-r', fps.toString(),
      '-c:v', 'mpeg4',
      '-q:v', '5',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-af', 'apad=pad_dur=${totalDuration.toStringAsFixed(2)}',
      '-y',
      outputPath,
    ]);

    final result = await _runner.run('ffmpeg', args);
    if (result.exitCode != 0) {
      throw ProcessingException(
        'فشل إخراج الفيديو',
        result.stderr.isEmpty ? result.stdout : result.stderr,
      );
    }
    return File(outputPath);
  }

  String _buildFilterComplex(FilterTheme filter, int bgCount, int ayahCount,
      List<double> durations, int width, int height) {
    final buffer = StringBuffer();
    final rawDuration = durations.fold(0.0, (sum, d) => sum + d);
    final totalDuration = rawDuration > 60.0 ? 60.0 : rawDuration;

    // 1. Build Background Source
    if (bgCount > 1) {
      // Slideshow logic
      final perImageDuration = totalDuration / bgCount;
      buffer.write('[0:v]scale=$width:$height,setsar=1[v_slideshow0];');
      for (var i = 1; i < bgCount; i++) {
        final startTime = i * perImageDuration;
        final nextLabel = i == bgCount - 1 ? '[v_bg_base]' : '[v_slideshow$i]';
        buffer.write('[v_slideshow${i - 1}][$i:v]scale=$width:$height,setsar=1,overlay=enable=\'gte(t,$startTime)\'$nextLabel;');
      }
    } else {
      // Single background
      buffer.write('[0:v]scale=$width:$height,setsar=1[v_bg_base];');
    }

    // 2. Add Decoration Pattern
    var currentBg = 'v_bg_base';
    if (filter.decorationPattern != DecorationPattern.none) {
      final decorLabel = 'v_decorated';
      switch (filter.decorationPattern) {
        case DecorationPattern.hexagon:
          buffer.write('[$currentBg]drawgrid=w=100:h=100:t=2:c=white@0.3[$decorLabel];');
          break;
        case DecorationPattern.dots:
          buffer.write('[$currentBg]noise=alls=50:allf=t+u[$decorLabel];');
          break;
        case DecorationPattern.islamic:
          buffer.write('[$currentBg]vignette=angle=0.5:x0=W/2:y0=H/2[$decorLabel];');
          break;
        default:
          buffer.write('[$currentBg]copy[$decorLabel];');
      }
      currentBg = decorLabel;
    }

    // 3. Overlay Ayah Text Images
    var currentTime = 0.0;
    var lastVLabel = currentBg;
    for (var i = 0; i < ayahCount; i++) {
      final inputIdx = bgCount + i;
      final startTime = currentTime;
      final endTime = currentTime + durations[i];
      currentTime = endTime;

      if (startTime >= 60.0) break;

      final isLast = (i == ayahCount - 1) || (endTime >= 60.0);
      final nextLabel = isLast ? 'v_out' : 'v_ayah$i';
      final effectiveEndTime = endTime > 60.0 ? 60.0 : endTime;
      final targetY = filter.textPosition == TextPosition.center ? '(H-h)/2' : '(H-h-200)';

      buffer.write(
          '[$lastVLabel][$inputIdx:v]overlay=x=(W-w)/2:y=$targetY:enable=\'between(t,$startTime,$effectiveEndTime)\'[$nextLabel];');
      lastVLabel = nextLabel;
      
      if (isLast) break;
    }

    if (lastVLabel != 'v_out') {
      buffer.write('[$lastVLabel]copy[v_out];');
    }

    return buffer.toString();
  }

  String _colorToHex(Color color) {
    String toHex(double value) =>
        (value * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${toHex(color.r)}${toHex(color.g)}${toHex(color.b)}';
  }
}
