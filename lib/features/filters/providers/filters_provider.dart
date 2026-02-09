import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/filter_model.dart';
import '../../../services/ffmpeg_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/file_utils.dart';

/// State for filters
class FiltersState {
  final Map<FilterType, double> activeFilters;
  final bool isProcessing;
  final double processingProgress;
  final String? error;
  final String? processedFilePath;

  const FiltersState({
    this.activeFilters = const {},
    this.isProcessing = false,
    this.processingProgress = 0.0,
    this.error,
    this.processedFilePath,
  });

  FiltersState copyWith({
    Map<FilterType, double>? activeFilters,
    bool? isProcessing,
    double? processingProgress,
    String? error,
    String? processedFilePath,
  }) {
    return FiltersState(
      activeFilters: activeFilters ?? this.activeFilters,
      isProcessing: isProcessing ?? this.isProcessing,
      processingProgress: processingProgress ?? this.processingProgress,
      error: error,
      processedFilePath: processedFilePath ?? this.processedFilePath,
    );
  }
}

/// Notifier for filters state management
class FiltersNotifier extends StateNotifier<FiltersState> {
  final FFmpegService _ffmpegService = FFmpegService();
  final StorageService _storageService = StorageService();

  FiltersNotifier() : super(const FiltersState());

  /// Update a filter value
  void updateFilter(FilterType type, double value) {
    final newFilters = Map<FilterType, double>.from(state.activeFilters);
    
    // Only add non-default values
    final filterModel = Filters.getFilterByType(type);
    if (filterModel != null) {
      if (value == filterModel.defaultValue) {
        newFilters.remove(type);
      } else {
        newFilters[type] = value;
      }
    }

    state = state.copyWith(activeFilters: newFilters);
  }

  /// Get current value of a filter
  double getFilterValue(FilterType type) {
    if (state.activeFilters.containsKey(type)) {
      return state.activeFilters[type]!;
    }
    
    final filterModel = Filters.getFilterByType(type);
    return filterModel?.defaultValue ?? 0;
  }

  /// Reset all filters
  void resetAllFilters() {
    state = const FiltersState();
  }

  /// Apply filters to media file
  Future<void> applyFilters(String inputPath, bool isVideo) async {
    try {
      state = state.copyWith(
        isProcessing: true,
        processingProgress: 0.0,
        error: null,
      );

      if (state.activeFilters.isEmpty) {
        throw ProcessingException('No filters selected');
      }

      // Create output path
      final outputDir = await _storageService.getTempDirectory();
      final outputFileName = FileUtils.generateUniqueFilename(inputPath);
      final outputPath = '${outputDir.path}/$outputFileName';

      // Convert FilterType map to String map for FFmpeg
      final filtersMap = <String, double>{};
      state.activeFilters.forEach((type, value) {
        filtersMap[type.ffmpegKey] = value;
      });

      // Build and execute FFmpeg command
      final command = isVideo
          ? _ffmpegService.buildVideoFilterCommand(
              inputPath: inputPath,
              outputPath: outputPath,
              filters: filtersMap,
            )
          : _ffmpegService.buildImageFilterCommand(
              inputPath: inputPath,
              outputPath: outputPath,
              filters: filtersMap,
            );

      final result = await _ffmpegService.executeCommand(
        command,
        onProgress: (progress) {
          state = state.copyWith(processingProgress: progress);
        },
      );

      state = state.copyWith(
        isProcessing: false,
        processedFilePath: result,
        processingProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  /// Cancel processing
  Future<void> cancelProcessing() async {
    await _ffmpegService.cancelCurrentSession();
    state = state.copyWith(
      isProcessing: false,
      processingProgress: 0.0,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear processed file
  void clearProcessedFile() {
    state = state.copyWith(processedFilePath: null);
  }
}

/// Provider for filters state
final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>(
  (ref) => FiltersNotifier(),
);
