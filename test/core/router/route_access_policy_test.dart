import 'package:ciervo_clud/app/route_access_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restringe consumo Movie a operaciones', () {
    expect(
      RouteAccessPolicy.canAccess('/movie/consume', AppRouteRole.client),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccess('/movie/consume', AppRouteRole.kid),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccess('/movie/consume', AppRouteRole.business),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccess('/movie/consume', AppRouteRole.staff),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccess('/movie/consume', AppRouteRole.admin),
      isTrue,
    );
  });

  test('separa solicitud, decisión y pago Movie', () {
    expect(
      RouteAccessPolicy.canAccess('/movie-requests/new', AppRouteRole.kid),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccess('/movie-requests/new', AppRouteRole.client),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccess('/movie-requests/req-1', AppRouteRole.client),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccess(
        '/movie/reservations/res-1/payment',
        AppRouteRole.kid,
      ),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccess('/movie/reservation', AppRouteRole.kid),
      isTrue,
    );
  });

  test('restringe Master y Business por rol', () {
    expect(
      RouteAccessPolicy.canAccess(
        '/master/kids/12/devices',
        AppRouteRole.client,
      ),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccess(
        '/master/kids/12/devices',
        AppRouteRole.business,
      ),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccess(
        '/business/kids-payment',
        AppRouteRole.business,
      ),
      isTrue,
    );
    expect(
      RouteAccessPolicy.canAccess(
        '/business/kids-payment',
        AppRouteRole.client,
      ),
      isFalse,
    );
    expect(
      RouteAccessPolicy.canAccess('/business/nfc', AppRouteRole.admin),
      isTrue,
    );
  });

  test('restringe onboarding MOVE Driver a Client explícito rol 1', () {
    const path = '/move/driver/onboarding/identity';
    expect(RouteAccessPolicy.canAccess(path, AppRouteRole.client), isTrue);
    expect(
      RouteAccessPolicy.canAccess(
        path,
        AppRouteRole.client,
        isExplicitClient: false,
      ),
      isFalse,
    );
    expect(RouteAccessPolicy.canAccess(path, AppRouteRole.kid), isFalse);
    expect(RouteAccessPolicy.canAccess(path, AppRouteRole.business), isFalse);
    expect(RouteAccessPolicy.canAccess(path, AppRouteRole.admin), isFalse);
  });
}
