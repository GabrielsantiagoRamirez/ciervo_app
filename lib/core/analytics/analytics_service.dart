abstract interface class AnalyticsService {
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  });

  Future<void> setUserId(String? userId);
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {}
}
