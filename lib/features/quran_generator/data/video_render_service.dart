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
    File? backgroundFile,
    required int width,
    required int height,
    int fps = 30,
  }) async {
    final outputPath = p.join(
      outputDir.path,
      'quran_reel_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    final totalDuration = durations.fold(0.0, (sum, d) => sum + d);
    final args = <String>[];

    // Input 0: Background
    if (filter.backgroundType == BackgroundType.solidColor) {
      final color = filter.backgroundColor ?? const Color(0xFF000000);
      args.addAll([
        '-f',
        'lavfi',
        '-i',
        'color=c=${_colorToHex(color)}:s=${width}x$height:r=$fps:d=$totalDuration',
      ]);
    } else if (filter.backgroundType == BackgroundType.gradientImage ||
        filter.backgroundType == BackgroundType.imageFile) {
      if (backgroundFile == null) {
        throw ProcessingException('Background image is missing');
      }
      args.addAll([
        '-loop',
        '1',
        '-i',
        backgroundFile.path,
      ]);
    } else if (filter.backgroundType == BackgroundType.videoFile) {
      if (backgroundFile == null) {
        throw ProcessingException('Background video is missing');
      }
      args.addAll([
        '-stream_loop',
        '-1',
        '-i',
        backgroundFile.path,
      ]);
    }

    // Input 1..N: Text Images
    for (final image in textImages) {
      args.addAll(['-i', image.path]);
    }

    // Last Input: Audio
    args.addAll(['-i', audioFile.path]);

    final audioInputIdx = textImages.length + 1;

    args.addAll([
      '-filter_complex',
      _buildFilterComplex(filter, textImages.length, durations, width, height),
      '-map',
      '[v_out]', // Map the labelled output from filter_complex
      '-map',
      '$audioInputIdx:a', // Map the audio from the last input
      '-t',
      totalDuration.toStringAsFixed(2),
      '-r',
      fps.toString(),
      '-c:v',
      'mpeg4',
      '-q:v',
      '5',
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-af',
      'apad=pad_dur=${totalDuration.toStringAsFixed(2)}', // Ensure audio matches video exactly
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

  String _buildFilterComplex(FilterTheme filter, int ayahCount,
      List<double> durations, int width, int height) {
    final buffer = StringBuffer();
    // Start with background scaling
    buffer.write('[0:v]scale=$width:$height,setsar=1[v_bg];');

    // Add Decoration Pattern if any
    var currentBg = 'v_bg';
    if (filter.decorationPattern != DecorationPattern.none) {
      final decorLabel = 'v_decorated';
      switch (filter.decorationPattern) {
        case DecorationPattern.hexagon:
          // Simulate hexagon/mesh with a grid filter
          buffer.write('[$currentBg]drawgrid=w=100:h=100:t=1:c=white@0.1[$decorLabel];');
          break;
        case DecorationPattern.dots:
          // Add some grain/dots
          buffer.write('[$currentBg]noise=alls=20:allf=t+u[$decorLabel];');
          break;
        case DecorationPattern.islamic:
          // Vignette for a more spiritual feel
          buffer.write('[$currentBg]vignette=angle=0.5[$decorLabel];');
          break;
        default:
          buffer.write('[$currentBg]copy[$decorLabel];');
      }
      currentBg = decorLabel;
    } else {
      buffer.write('[$currentBg]copy[v_decorated];');
      currentBg = 'v_decorated';
    }

    buffer.write('[$currentBg]copy[v0];');

    var currentTime = 0.0;
    for (var i = 0; i < ayahCount; i++) {
      final inputIdx = i + 1;
      final startTime = currentTime;
      final endTime = currentTime + durations[i];
      currentTime = endTime;

      final prevLabel = 'v$i';
      final nextLabel = i == ayahCount - 1 ? 'v_out' : 'v${i + 1}';

      final targetY = filter.textPosition == TextPosition.center
          ? '(H-h)/2'
          : '(H-h-200)';

      buffer.write(
          '[$prevLabel][$inputIdx:v]overlay=x=(W-w)/2:y=$targetY:enable=\'between(t,$startTime,$endTime)\'[$nextLabel];');
    }

    return buffer.toString();
  }

  String _colorToHex(Color color) {
    String toHex(double value) =>
        (value * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${toHex(color.r)}${toHex(color.g)}${toHex(color.b)}';
  }
}
