import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/statistics.dart';
import '../core/errors/exceptions.dart';

/// FFmpeg Service for media processing
/// Handles all video and image filter operations
class FFmpegService {
  // Singleton pattern
  static final FFmpegService _instance = FFmpegService._internal();
  factory FFmpegService() => _instance;
  FFmpegService._internal();

  /// Execute FFmpeg command with progress tracking
  /// 
  /// [command] - The FFmpeg command to execute
  /// [onProgress] - Callback for progress updates (0.0 to 1.0)
  /// Returns the output file path if successful
  Future<String> executeCommand(
    String command, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final completer = Completer<String>();
      double totalDuration = 0;

      // Enable statistics callback for progress tracking
      FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
        if (onProgress != null && totalDuration > 0) {
          final time = statistics.getTime();
          final progress = (time / totalDuration).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });

      // Execute FFmpeg command
      FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          
          if (ReturnCode.isSuccess(returnCode)) {
            // Extract output file path from command
            final outputPath = _extractOutputPath(command);
            if (outputPath != null && await File(outputPath).exists()) {
              completer.complete(outputPath);
            } else {
              completer.completeError(
                ProcessingException(
                  'Output file not found',
                  'Expected output at: $outputPath',
                ),
              );
            }
          } else {
            final failStackTrace = await session.getFailStackTrace();
            completer.completeError(
              ProcessingException(
                'FFmpeg command failed',
                'Return code: $returnCode\n$failStackTrace',
              ),
            );
          }
        },
        (log) {
          // Extract total duration from FFmpeg logs
          if (totalDuration == 0) {
            totalDuration = _extractDurationFromLog(log);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      throw ProcessingException('Failed to execute FFmpeg command', e.toString());
    }
  }

  /// Build FFmpeg command for applying filters to video
  /// 
  /// [inputPath] - Path to input video file
  /// [outputPath] - Path where output will be saved
  /// [filters] - Map of filter names to their values
  String buildVideoFilterCommand({
    required String inputPath,
    required String outputPath,
    required Map<String, double> filters,
  }) {
    final filterStrings = <String>[];

    // Build filter chain
    if (filters.containsKey('blur')) {
      final blurValue = filters['blur']!;
      filterStrings.add('boxblur=${blurValue.toInt()}:1');
    }

    if (filters.containsKey('brightness')) {
      final brightnessValue = filters['brightness']!;
      filterStrings.add('eq=brightness=$brightnessValue');
    }

    if (filters.containsKey('contrast')) {
      final contrastValue = filters['contrast']!;
      filterStrings.add('eq=contrast=$contrastValue');
    }

    if (filters.containsKey('saturation')) {
      final saturationValue = filters['saturation']!;
      filterStrings.add('eq=saturation=$saturationValue');
    }

    if (filters.containsKey('grayscale')) {
      filterStrings.add('colorchannelmixer=.3:.4:.3:0:.3:.4:.3:0:.3:.4:.3');
    }

    if (filters.containsKey('sepia')) {
      filterStrings.add('colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131');
    }

    // Fade effects
    if (filters.containsKey('fade_in')) {
      final fadeDuration = filters['fade_in']!.toInt();
      filterStrings.add('fade=in:0:$fadeDuration');
    }

    if (filters.containsKey('fade_out')) {
      final fadeDuration = filters['fade_out']!.toInt();
      // Fade out at the end (we'll calculate the start frame later)
      filterStrings.add('fade=out:st=0:d=$fadeDuration');
    }

    // Combine all filters
    final filterChain = filterStrings.isEmpty 
        ? '' 
        : '-vf "${filterStrings.join(',')}"';

    // Build complete command
    return '-i "$inputPath" $filterChain -c:a copy -y "$outputPath"';
  }

  /// Build FFmpeg command for applying filters to images
  /// 
  /// [inputPath] - Path to input image file
  /// [outputPath] - Path where output will be saved
  /// [filters] - Map of filter names to their values
  String buildImageFilterCommand({
    required String inputPath,
    required String outputPath,
    required Map<String, double> filters,
  }) {
    final filterStrings = <String>[];

    // Build filter chain (similar to video but without audio)
    if (filters.containsKey('blur')) {
      final blurValue = filters['blur']!;
      filterStrings.add('boxblur=${blurValue.toInt()}:1');
    }

    if (filters.containsKey('brightness')) {
      final brightnessValue = filters['brightness']!;
      filterStrings.add('eq=brightness=$brightnessValue');
    }

    if (filters.containsKey('contrast')) {
      final contrastValue = filters['contrast']!;
      filterStrings.add('eq=contrast=$contrastValue');
    }

    if (filters.containsKey('saturation')) {
      final saturationValue = filters['saturation']!;
      filterStrings.add('eq=saturation=$saturationValue');
    }

    if (filters.containsKey('grayscale')) {
      filterStrings.add('colorchannelmixer=.3:.4:.3:0:.3:.4:.3:0:.3:.4:.3');
    }

    if (filters.containsKey('sepia')) {
      filterStrings.add('colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131');
    }

    // Combine all filters
    final filterChain = filterStrings.isEmpty 
        ? '' 
        : '-vf "${filterStrings.join(',')}"';

    // Build complete command
    return '-i "$inputPath" $filterChain -y "$outputPath"';
  }

  /// Cancel any running FFmpeg session
  Future<void> cancelCurrentSession() async {
    await FFmpegKit.cancel();
  }

  /// Extract output file path from FFmpeg command
  String? _extractOutputPath(String command) {
    // Look for the last quoted path or the last path before -y flag
    final regex = RegExp(r'"([^"]+)"\s*$');
    final match = regex.firstMatch(command);
    return match?.group(1);
  }

  /// Extract video duration from FFmpeg log
  double _extractDurationFromLog(Log log) {
    final message = log.getMessage();
    // Look for Duration: HH:MM:SS.ms pattern
    final durationRegex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})');
    final match = durationRegex.firstMatch(message);
    
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final milliseconds = int.parse(match.group(4)!) * 10;
      
      return (hours * 3600 + minutes * 60 + seconds) * 1000.0 + milliseconds;
    }
    
    return 0;
  }
}
