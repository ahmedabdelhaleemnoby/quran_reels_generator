/// Model representing a selected media file
class MediaModel {
  final String path;
  final MediaType type;
  final int sizeBytes;
  final String? thumbnailPath;

  const MediaModel({
    required this.path,
    required this.type,
    required this.sizeBytes,
    this.thumbnailPath,
  });

  /// Check if media is a video
  bool get isVideo => type == MediaType.video;

  /// Check if media is an image
  bool get isImage => type == MediaType.image;

  /// Get file extension
  String get extension {
    return path.split('.').last.toLowerCase();
  }

  /// Get filename
  String get filename {
    return path.split('/').last;
  }

  /// Format file size to human-readable string
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  MediaModel copyWith({
    String? path,
    MediaType? type,
    int? sizeBytes,
    String? thumbnailPath,
  }) {
    return MediaModel(
      path: path ?? this.path,
      type: type ?? this.type,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}

/// Enum for media types
enum MediaType {
  image,
  video,
}
