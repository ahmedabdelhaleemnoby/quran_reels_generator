import 'dart:io';
import 'package:path/path.dart' as path;

/// File utilities for media handling
class FileUtils {
  FileUtils._();

  /// Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceAll('.', '');
  }

  /// Check if file is an image
  static bool isImage(String filePath) {
    final ext = getFileExtension(filePath);
    return ['jpg', 'jpeg', 'png', 'heic', 'gif'].contains(ext);
  }

  /// Check if file is a video
  static bool isVideo(String filePath) {
    final ext = getFileExtension(filePath);
    return ['mp4', 'mov', 'avi', 'mkv', 'flv'].contains(ext);
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  /// Format file size (bytes to human-readable)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Generate unique filename
  static String generateUniqueFilename(String originalPath, {String? prefix}) {
    final ext = getFileExtension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefixStr = prefix != null ? '${prefix}_' : '';
    return '${prefixStr}filtered_$timestamp.$ext';
  }

  /// Delete file if exists
  static Future<void> deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
