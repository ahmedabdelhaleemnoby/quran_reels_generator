import 'dart:io';

import 'package:ffmpeg_kit_flutter_full/ffprobe_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/errors/exceptions.dart';
import '../domain/audio_track.dart';
import '../domain/reciter.dart';
import 'command_runner.dart';
import 'reciter_service.dart';

class AudioService {
  AudioService({
    http.Client? client,
    ReciterService? reciterService,
    CommandRunner? runner,
  })  : _client = client ?? http.Client(),
        _reciterService = reciterService ?? ReciterService(),
        _runner = runner ?? CommandRunner();

  final http.Client _client;
  final ReciterService _reciterService;
  final CommandRunner _runner;

  Future<AudioTrack> buildAudioTrack({
    required Reciter reciter,
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required Directory outputDir,
    void Function(double progress)? onProgress,
  }) async {
    final ayahFiles = <File>[];
    final ayahDurations = <double>[];
    final total = toAyah - fromAyah + 1;
    var completed = 0;

    for (var ayah = fromAyah; ayah <= toAyah; ayah++) {
      final url = _reciterService.buildAyahAudioUrl(
        reciter: reciter,
        surahNumber: surahNumber,
        ayahNumber: ayah,
      );
      final file = await _downloadAyah(url, outputDir, surahNumber, ayah);
      ayahFiles.add(file);
      
      // Get duration of this ayah
      final duration = await _getDuration(file.path);
      ayahDurations.add(duration);
      
      completed += 1;
      onProgress?.call(completed / total);
    }

    final combinedFile = await _concatAudioFiles(ayahFiles, outputDir);
    return AudioTrack(file: combinedFile, ayahDurations: ayahDurations);
  }

  Future<double> _getDuration(String path) async {
    final session = await FFprobeKit.execute(
        "-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \"$path\"");
    final output = await session.getOutput();
    if (output == null || output.trim().isEmpty) {
      return 0.0;
    }
    return double.tryParse(output.trim()) ?? 0.0;
  }

  Future<File> _downloadAyah(
    String url,
    Directory outputDir,
    int surahNumber,
    int ayahNumber,
  ) async {
    final fileName =
        '${surahNumber.toString().padLeft(3, '0')}${ayahNumber.toString().padLeft(3, '0')}.mp3';
    final outputPath = p.join(outputDir.path, fileName);
    final file = File(outputPath);
    if (await file.exists()) {
      return file;
    }

    final request = http.Request('GET', Uri.parse(url));
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw ProcessingException('Failed to download audio', url);
    }
    final sink = file.openWrite();
    await response.stream.pipe(sink);
    await sink.flush();
    await sink.close();
    return file;
  }

  Future<File> _concatAudioFiles(List<File> files, Directory outputDir) async {
    if (files.isEmpty) {
      throw ProcessingException('No audio files to concatenate');
    }
    final listFile = File(p.join(outputDir.path, 'concat_list.txt'));
    final buffer = StringBuffer();
    for (final file in files) {
      buffer.writeln("file '${file.path.replaceAll("'", r"'\''")}'");
    }
    await listFile.writeAsString(buffer.toString());

    final outputPath = p.join(outputDir.path, 'combined_audio.mp3');

    final primaryResult = await _runner.run('ffmpeg', [
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      listFile.path,
      '-c',
      'copy',
      outputPath,
    ]);

    if (primaryResult.exitCode == 0) {
      return File(outputPath);
    }

    final fallbackResult = await _runner.run('ffmpeg', [
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      listFile.path,
      '-c:a',
      'libmp3lame',
      '-q:a',
      '3',
      outputPath,
    ]);

    if (fallbackResult.exitCode != 0) {
      throw ProcessingException(
        'Failed to concatenate audio',
        fallbackResult.stderr.isEmpty ? fallbackResult.stdout : fallbackResult.stderr,
      );
    }

    return File(outputPath);
  }
}
