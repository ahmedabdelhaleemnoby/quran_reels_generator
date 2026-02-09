import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quran_video_generator.dart';
import '../domain/generation_request.dart';

class GenerationState {
  final bool isGenerating;
  final double progress;
  final String statusMessage;
  final String? outputPath;
  final String? error;

  const GenerationState({
    this.isGenerating = false,
    this.progress = 0,
    this.statusMessage = '',
    this.outputPath,
    this.error,
  });

  GenerationState copyWith({
    bool? isGenerating,
    double? progress,
    String? statusMessage,
    String? outputPath,
    String? error,
  }) {
    return GenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      outputPath: outputPath ?? this.outputPath,
      error: error,
    );
  }
}

class GenerationNotifier extends StateNotifier<GenerationState> {
  GenerationNotifier() : super(const GenerationState());

  final QuranVideoGenerator _generator = QuranVideoGenerator();

  Future<void> generate(GenerationRequest request) async {
    state = state.copyWith(
      isGenerating: true,
      progress: 0,
      statusMessage: 'بدء المعالجة',
      outputPath: null,
      error: null,
    );

    try {
      final outputFile = await _generator.generate(
        request: request,
        onProgress: (progress, message) {
          state = state.copyWith(
            progress: progress,
            statusMessage: message,
          );
        },
      );
      state = state.copyWith(
        isGenerating: false,
        progress: 1,
        statusMessage: 'تم إنشاء الفيديو',
        outputPath: outputFile.path,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
        statusMessage: 'فشل التوليد',
      );
    }
  }

  void reset() {
    state = const GenerationState();
  }
}

final generationProvider =
    StateNotifierProvider<GenerationNotifier, GenerationState>(
  (ref) => GenerationNotifier(),
);
