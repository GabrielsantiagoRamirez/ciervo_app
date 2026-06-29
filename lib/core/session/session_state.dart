enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState {
  const SessionState._(this.status);

  const SessionState.unknown() : this._(SessionStatus.unknown);

  const SessionState.authenticated() : this._(SessionStatus.authenticated);

  const SessionState.unauthenticated() : this._(SessionStatus.unauthenticated);

  final SessionStatus status;

  bool get isAuthenticated => status == SessionStatus.authenticated;
}
