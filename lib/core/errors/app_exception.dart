class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.correlationId,
    this.fieldErrors = const <String, List<String>>{},
    this.cause,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final String? correlationId;
  final Map<String, List<String>> fieldErrors;
  final Object? cause;

  @override
  String toString() {
    final codeLabel = code == null ? '' : ' [$code]';
    final statusLabel = statusCode == null ? '' : ' ($statusCode)';
    return 'AppException$codeLabel$statusLabel: $message';
  }
}
