class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.cause,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final codeLabel = code == null ? '' : ' [$code]';
    final statusLabel = statusCode == null ? '' : ' ($statusCode)';
    return 'AppException$codeLabel$statusLabel: $message';
  }
}
