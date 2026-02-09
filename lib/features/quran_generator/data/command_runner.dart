import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';

import '../../../core/errors/exceptions.dart';

class CommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

class CommandRunner {
  Future<CommandResult> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    try {
      // ffmpeg_kit handles the 'ffmpeg' executable name by default.
      // For other commands (like ImageMagick), we can't use Process.run on mobile.
      // We focus on FFmpeg commands here.
      if (executable != 'ffmpeg') {
        throw ProcessingException(
          'Command not supported on mobile',
          executable,
        );
      }

      final session = await FFmpegKit.executeWithArguments(args);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      final failStackTrace = await session.getFailStackTrace();

      return CommandResult(
        exitCode: ReturnCode.isSuccess(returnCode) ? 0 : 1,
        stdout: output ?? '',
        stderr: failStackTrace ?? '',
      );
    } catch (e) {
      throw ProcessingException('Failed to run FFmpeg command', '$args\n$e');
    }
  }
}
