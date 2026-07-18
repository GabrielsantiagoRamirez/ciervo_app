enum AppRouteRole { client, kid, business, admin, staff }

abstract final class RouteAccessPolicy {
  static AppRouteRole roleFromRouteKind(String routeKind) {
    return switch (routeKind) {
      'Kid' => AppRouteRole.kid,
      'BusinessOwner' => AppRouteRole.business,
      'SuperAdmin' => AppRouteRole.admin,
      'Staff' => AppRouteRole.staff,
      _ => AppRouteRole.client,
    };
  }

  static bool canAccess(String path, AppRouteRole role) {
    final normalized = Uri.tryParse(path)?.path ?? path;

    if (normalized == '/movie/consume') {
      return {AppRouteRole.business, AppRouteRole.admin}.contains(role);
    }
    if (normalized == '/business/kids-payment' ||
        normalized == '/business/nfc') {
      return {AppRouteRole.business, AppRouteRole.admin}.contains(role);
    }
    if (normalized == '/master/payment-requests' ||
        normalized.startsWith('/master/kids/')) {
      return role == AppRouteRole.client;
    }
    if (normalized == '/movie-requests/new') {
      return role == AppRouteRole.kid;
    }
    if (normalized.startsWith('/movie-requests/')) {
      return {AppRouteRole.client, AppRouteRole.kid}.contains(role);
    }
    if (normalized.startsWith('/movie/reservations/') &&
        normalized.endsWith('/payment')) {
      return role == AppRouteRole.client;
    }
    if (normalized == '/movie/reservation') {
      return {AppRouteRole.client, AppRouteRole.kid}.contains(role);
    }
    if (normalized.startsWith('/movie/qr/')) {
      return {AppRouteRole.client, AppRouteRole.kid}.contains(role);
    }
    if (normalized == '/kids-v2/qr') {
      return role == AppRouteRole.kid;
    }
    if (normalized == '/movies' ||
        normalized.startsWith('/movies/') ||
        normalized == '/movie/history') {
      return {AppRouteRole.client, AppRouteRole.kid}.contains(role);
    }

    return true;
  }
}
