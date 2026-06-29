enum AuthSubmissionStatus { idle, loading, success, failure }

class AuthState {
  const AuthState({
    this.status = AuthSubmissionStatus.idle,
    this.errorMessage,
  });

  final AuthSubmissionStatus status;
  final String? errorMessage;

  bool get isLoading => status == AuthSubmissionStatus.loading;

  AuthState copyWith({
    AuthSubmissionStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
