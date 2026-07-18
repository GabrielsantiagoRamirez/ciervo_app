class NotificationDeepLinkParser {
  const NotificationDeepLinkParser._();

  static const _webHosts = {
    'ciervo.club',
    'www.ciervo.club',
    'app.ciervo.club',
  };

  static final RegExp _safeSegment = RegExp(r'^[a-zA-Z0-9._~-]{1,128}$');

  static String? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty ||
        value.length > 2048 ||
        value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
      return null;
    }
    final lowerValue = value.toLowerCase();
    if (value.contains(r'\') ||
        lowerValue.contains('%2e') ||
        lowerValue.contains('%2f') ||
        lowerValue.contains('%5c') ||
        RegExp(r'(^|/)\.{1,2}(/|$)').hasMatch(value)) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        uri.hasQuery) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    final segments = <String>[];
    if (scheme.isEmpty) {
      segments.addAll(uri.pathSegments);
    } else if (scheme == 'ciervo') {
      if (uri.host.isNotEmpty) segments.add(uri.host);
      segments.addAll(uri.pathSegments);
    } else if (scheme == 'https' &&
        _webHosts.contains(uri.host.toLowerCase())) {
      segments.addAll(uri.pathSegments);
      if (segments.isNotEmpty && segments.first.toLowerCase() == 'app') {
        segments.removeAt(0);
      }
    } else {
      return null;
    }

    final clean = segments.where((segment) => segment.isNotEmpty).toList();
    if (clean.isEmpty ||
        clean.any(
          (segment) =>
              segment == '.' ||
              segment == '..' ||
              !_safeSegment.hasMatch(segment),
        )) {
      return null;
    }
    return _canonicalize(clean);
  }

  static String? _canonicalize(List<String> segments) {
    final lower = segments.map((item) => item.toLowerCase()).toList();
    final root = lower.first;

    if (_matches(lower, ['movie', 'request'], id: true) ||
        _matches(lower, ['movie-requests'], id: true)) {
      return '/movie-requests/${segments.last}';
    }
    if (_matches(lower, ['movie', 'reservation'], id: true)) {
      return '/movie/qr/${segments.last}';
    }
    if (_matches(lower, ['movie', 'qr'], id: true)) {
      return '/movie/qr/${segments.last}';
    }
    if (_matches(lower, ['movie', 'chat'], id: true)) {
      return '/chat/${segments.last}';
    }
    if (_matches(lower, ['movie', 'reservations'], id: true, tail: 'payment')) {
      return '/movie/reservations/${segments[2]}/payment';
    }
    if (_matches(lower, ['kids', 'request'], id: true)) {
      return '/master/payment-requests';
    }
    if (_matches(lower, ['kids', 'device'], id: true)) {
      return '/master/kids/${segments.last}/devices';
    }
    if (lower.length == 4 &&
        root == 'master' &&
        lower[1] == 'kids' &&
        {'devices', 'security', 'rules'}.contains(lower[3])) {
      return '/${segments.join('/')}';
    }
    if (lower.length == 2 &&
        root == 'master' &&
        lower[1] == 'payment-requests') {
      return '/master/payment-requests';
    }

    const rootsWithoutId = {
      'vakupli',
      'campaign',
      'ads',
      'wallet',
      'nfc',
      'qr',
      'profile',
      'security',
      'settings',
    };
    const rootsWithOptionalId = {
      'chat',
      'conversations',
      'payment-request',
      'payment_request',
      'bonus',
      'bonuses',
      'move',
      'ride',
      'trip',
      'delivery',
      'orders',
      'reservations',
      'booking',
      'events',
      'ticket',
      'promotions',
      'coupon',
      'rewards',
    };
    if ((rootsWithoutId.contains(root) && lower.length == 1) ||
        (rootsWithOptionalId.contains(root) && lower.length <= 2) ||
        (root == 'wallet' &&
            lower.length == 2 &&
            {'payment-request', 'payment_request'}.contains(lower[1])) ||
        ({'secure-shipment', 'secure_shipment'}.contains(root) &&
            lower.length == 2)) {
      return '/${segments.join('/')}';
    }
    return null;
  }

  static bool _matches(
    List<String> actual,
    List<String> prefix, {
    required bool id,
    String? tail,
  }) {
    final expectedLength =
        prefix.length + (id ? 1 : 0) + (tail == null ? 0 : 1);
    if (actual.length != expectedLength) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (actual[index] != prefix[index]) return false;
    }
    return tail == null || actual.last == tail;
  }
}
