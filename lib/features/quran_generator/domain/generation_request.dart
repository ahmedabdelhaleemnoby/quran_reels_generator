import 'filter_theme.dart';
import 'reciter.dart';
import 'surah.dart';

class GenerationRequest {
  final Reciter reciter;
  final Surah surah;
  final int fromAyah;
  final int toAyah;
  final int durationSeconds;
  final FilterTheme filter;
  final String? customAudioPath;
  final List<String>? backgroundPaths;

  const GenerationRequest({
    required this.reciter,
    required this.surah,
    required this.fromAyah,
    required this.toAyah,
    required this.durationSeconds,
    required this.filter,
    this.customAudioPath,
    this.backgroundPaths,
  });
}
