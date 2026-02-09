import 'package:permission_handler/permission_handler.dart';
import '../core/errors/exceptions.dart';

/// Service for handling app permissions
class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request storage permission
  /// Required for reading and writing media files
  Future<bool> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        throw PermissionException(
          'Storage permission permanently denied',
          'Please enable storage permission in app settings',
        );
      }
      
      return false;
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw PermissionException('Failed to request storage permission', e.toString());
    }
  }

  /// Request photo library permission (iOS specific)
  Future<bool> requestPhotoLibraryPermission() async {
    try {
      final status = await Permission.photos.request();
      
      if (status.isGranted || status.isLimited) {
        return true;
      } else if (status.isPermanentlyDenied) {
        throw PermissionException(
          'Photo library permission permanently denied',
          'Please enable photo library access in app settings',
        );
      }
      
      return false;
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw PermissionException('Failed to request photo library permission', e.toString());
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        throw PermissionException(
          'Camera permission permanently denied',
          'Please enable camera access in app settings',
        );
      }
      
      return false;
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw PermissionException('Failed to request camera permission', e.toString());
    }
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  /// Check if photo library permission is granted
  Future<bool> hasPhotoLibraryPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Request all necessary permissions for media access
  Future<bool> requestMediaPermissions() async {
    // On iOS, request photo library permission
    // On Android, request storage permission
    if (await hasPhotoLibraryPermission()) {
      return true;
    }
    
    if (await hasStoragePermission()) {
      return true;
    }

    // Try requesting photo library first (works on iOS)
    bool granted = await requestPhotoLibraryPermission();
    if (!granted) {
      // Fallback to storage permission (Android)
      granted = await requestStoragePermission();
    }

    return granted;
  }
}
