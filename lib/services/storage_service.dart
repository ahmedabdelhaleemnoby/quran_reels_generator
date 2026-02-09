import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';

/// Service for file storage and sharing operations
class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Get temporary directory for processing
  Future<Directory> getTempDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final appTempDir = Directory('${tempDir.path}/${AppConstants.tempFolderName}');
      
      if (!await appTempDir.exists()) {
        await appTempDir.create(recursive: true);
      }
      
      return appTempDir;
    } catch (e) {
      throw StorageException('Failed to access temporary directory', e.toString());
    }
  }

  /// Get directory for saving processed media (Downloads folder for Android, Documents for iOS)
  Future<Directory> getOutputDirectory() async {
    try {
      if (Platform.isIOS) {
        // downloads on iOS is restricted, use documents
        final appDocDir = await getApplicationDocumentsDirectory();
        final outputDir = Directory('${appDocDir.path}/${AppConstants.outputFolderName}');
        if (!await outputDir.exists()) {
          await outputDir.create(recursive: true);
        }
        return outputDir;
      }

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      
      final outputDir = Directory('${downloadsDir?.path ?? (await getApplicationDocumentsDirectory()).path}/${AppConstants.outputFolderName}');
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      return outputDir;
    } catch (e) {
      // Fallback if anything fails
      final appDocDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${appDocDir.path}/${AppConstants.outputFolderName}');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      return outputDir;
    }
  }

  /// Save file to gallery/photos
  /// Note: This copies the file to app's documents directory
  /// For actual gallery saving, you'd need image_gallery_saver package
  Future<String> saveToGallery(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileException('Source file not found', filePath);
      }

      final outputDir = await getOutputDirectory();
      if (filePath.startsWith(outputDir.path)) {
        return filePath;
      }
      final fileName = filePath.split('/').last;
      final newPath = '${outputDir.path}/$fileName';
      
      await file.copy(newPath);
      return newPath;
    } catch (e) {
      if (e is AppException) rethrow;
      throw StorageException('Failed to save file', e.toString());
    }
  }

  /// Share media file
  Future<void> shareMedia(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileException('File not found', filePath);
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Shared from ${AppConstants.appName}',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw StorageException('Failed to share file', e.toString());
    }
  }

  /// Clean up temporary files
  Future<void> cleanTempDirectory() async {
    try {
      final tempDir = await getTempDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create(recursive: true);
      }
    } catch (e) {
      // Silently fail - cleaning temp is not critical
      debugPrint('Warning: Failed to clean temp directory: $e');
    }
  }

  /// Get available storage space (in bytes)
  Future<int?> getAvailableSpace() async {
    try {
      // This is a simplified version
      // For production, use a package like disk_space
      // Note: This might not work on all platforms
      return null; // Placeholder
    } catch (e) {
      return null;
    }
  }

  /// Delete file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileException('Failed to delete file', e.toString());
    }
  }

  /// Copy file to temp directory
  Future<String> copyToTemp(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileException('Source file not found', sourcePath);
      }

      final tempDir = await getTempDirectory();
      final fileName = sourcePath.split('/').last;
      final tempPath = '${tempDir.path}/$fileName';
      
      await sourceFile.copy(tempPath);
      return tempPath;
    } catch (e) {
      if (e is AppException) rethrow;
      throw StorageException('Failed to copy file to temp', e.toString());
    }
  }
}
