import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

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
      // FFmpegKit only supports ffmpeg and ffprobe
      if (executable != 'ffmpeg' && executable != 'ffprobe') {
        throw ProcessingException(
          'Command not supported',
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
      throw ProcessingException(
        'Failed to run $executable command',
        '$args\n$e',
      );
    }
  }
}
