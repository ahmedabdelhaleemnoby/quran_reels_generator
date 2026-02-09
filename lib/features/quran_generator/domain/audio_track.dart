import 'dart:io';

class AudioTrack {
  final File file;
  final List<double> ayahDurations;

  const AudioTrack({
    required this.file,
    required this.ayahDurations,
  });

  double get totalDuration => ayahDurations.fold(0, (sum, d) => sum + d);
}
