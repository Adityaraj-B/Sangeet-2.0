class MusicException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const MusicException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (originalError != null) {
      return 'MusicException: $message (Caused by: $originalError)';
    }
    return 'MusicException: $message';
  }
}
