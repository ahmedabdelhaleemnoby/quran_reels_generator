import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage_service.dart';

/// State for export feature
class ExportState {
  final bool isExporting;
  final bool isSaved;
  final bool isShared;
  final String? error;
  final String? savedPath;

  const ExportState({
    this.isExporting = false,
    this.isSaved = false,
    this.isShared = false,
    this.error,
    this.savedPath,
  });

  ExportState copyWith({
    bool? isExporting,
    bool? isSaved,
    bool? isShared,
    String? error,
    String? savedPath,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      isSaved: isSaved ?? this.isSaved,
      isShared: isShared ?? this.isShared,
      error: error,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}

/// Notifier for export state management
class ExportNotifier extends StateNotifier<ExportState> {
  final StorageService _storageService = StorageService();

  ExportNotifier() : super(const ExportState());

  /// Save processed media to gallery
  Future<void> saveToGallery(String filePath) async {
    try {
      state = state.copyWith(isExporting: true, error: null);

      final savedPath = await _storageService.saveToGallery(filePath);

      state = state.copyWith(
        isExporting: false,
        isSaved: true,
        savedPath: savedPath,
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  /// Share processed media
  Future<void> shareMedia(String filePath) async {
    try {
      state = state.copyWith(isExporting: true, error: null);

      await _storageService.shareMedia(filePath);

      state = state.copyWith(
        isExporting: false,
        isShared: true,
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  /// Reset export state
  void reset() {
    state = const ExportState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for export state
final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>(
  (ref) => ExportNotifier(),
);
