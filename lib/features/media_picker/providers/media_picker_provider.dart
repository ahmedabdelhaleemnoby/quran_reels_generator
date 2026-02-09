import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/exceptions.dart';
import '../../../services/permission_service.dart';
import '../domain/media_model.dart';

/// State for media picker
class MediaPickerState {
  final MediaModel? selectedMedia;
  final bool isLoading;
  final String? error;

  const MediaPickerState({
    this.selectedMedia,
    this.isLoading = false,
    this.error,
  });

  MediaPickerState copyWith({
    MediaModel? selectedMedia,
    bool? isLoading,
    String? error,
  }) {
    return MediaPickerState(
      selectedMedia: selectedMedia ?? this.selectedMedia,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for media picker state management
class MediaPickerNotifier extends StateNotifier<MediaPickerState> {
  final ImagePicker _imagePicker = ImagePicker();
  final PermissionService _permissionService = PermissionService();

  MediaPickerNotifier() : super(const MediaPickerState());

  /// Pick an image from gallery
  Future<void> pickImage() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check permissions
      final hasPermission = await _permissionService.requestMediaPermissions();
      if (!hasPermission) {
        throw PermissionException('Media access permission denied');
      }

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final size = await file.length();

        final media = MediaModel(
          path: pickedFile.path,
          type: MediaType.image,
          sizeBytes: size,
        );

        state = state.copyWith(
          selectedMedia: media,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Pick a video from gallery
  Future<void> pickVideo() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check permissions
      final hasPermission = await _permissionService.requestMediaPermissions();
      if (!hasPermission) {
        throw PermissionException('Media access permission denied');
      }

      // Pick video
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final size = await file.length();

        final media = MediaModel(
          path: pickedFile.path,
          type: MediaType.video,
          sizeBytes: size,
        );

        state = state.copyWith(
          selectedMedia: media,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear selected media
  void clearSelection() {
    state = const MediaPickerState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for media picker state
final mediaPickerProvider = StateNotifierProvider<MediaPickerNotifier, MediaPickerState>(
  (ref) => MediaPickerNotifier(),
);
