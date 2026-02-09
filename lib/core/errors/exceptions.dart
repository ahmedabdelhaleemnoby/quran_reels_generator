/// Base class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? details;

  AppException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return '$message: $details';
    }
    return message;
  }
}

/// Exception for file-related errors
class FileException extends AppException {
  FileException(super.message, [super.details]);
}

/// Exception for permission-related errors
class PermissionException extends AppException {
  PermissionException(super.message, [super.details]);
}

/// Exception for FFmpeg processing errors
class ProcessingException extends AppException {
  ProcessingException(super.message, [super.details]);
}

/// Exception for unsupported media types
class UnsupportedMediaException extends AppException {
  UnsupportedMediaException(super.message, [super.details]);
}

/// Exception for storage/space errors
class StorageException extends AppException {
  StorageException(super.message, [super.details]);
}
